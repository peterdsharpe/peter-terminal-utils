#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, and pipeline failures

###############################################################################
### Peter Sharpe's Linux Setup Script - Orchestrator
###############################################################################
#
# This script orchestrates the installation of all components by:
# 1. Gathering configuration from the user
# 2. Parsing the install_scripts/order.yaml manifest
# 3. Running each install script with framed output display
# 4. Showing a summary of results
#
# Individual scripts can also be run standalone for targeted installation.
#
###############################################################################

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared utilities
source "$SCRIPT_DIR/_common.sh"

###############################################################################
### Framed Execution System
###############################################################################

# Track results for summary
declare -a COMPLETED_SCRIPTS=()
declare -a FAILED_SCRIPTS=()
declare -a SKIPPED_SCRIPTS=()

# Run a script with framed output that clears on success
run_framed() {
    local display_name="$1"
    local script_path="$2"
    local tmp_count
    tmp_count=$(mktemp)
    local line_count=0
    
    # Top border with name
    echo -e "${CYAN}╔══ ${BOLD}${display_name}${NC}${CYAN} ══════════════════════════════════════════════════════════════╗${NC}"
    
    # Run script in subshell by sourcing (utilities already in scope)
    # _SOURCED=1 tells the script to skip its trampoline
    # Use set +e to prevent script from exiting on failure
    set +e
    {
        ( export _SOURCED=1; source "$script_path" ) 2>&1
    } | {
        while IFS= read -r line || [[ -n "$line" ]]; do
            echo -e "${CYAN}║${NC} $line"
            ((line_count++))
        done
        echo "$line_count" > "$tmp_count"
    }
    local exit_code=${PIPESTATUS[0]}
    set -e
    
    # Read line count from temp file (subshell variable doesn't propagate)
    line_count=$(cat "$tmp_count")
    rm -f "$tmp_count"
    
    if [[ $exit_code -eq 0 ]]; then
        # Success - clear the framed output
        local total=$((line_count + 1))  # +1 for header
        
        # Move cursor up and clear each line
        printf '\033[%dA' "$total"
        for ((i = 0; i < total; i++)); do
            printf '\033[2K'  # Clear line
            printf '\n'
        done
        printf '\033[%dA' "$total"  # Move back up
        
        # Print success message
        echo -e "${GREEN}✓${NC} ${display_name}"
        COMPLETED_SCRIPTS+=("$display_name")
    else
        # Failure - print footer and leave output visible
        echo -e "${CYAN}╚══${RED} ✗ Failed (exit code: $exit_code) ${CYAN}═══════════════════════════════════════════════════════╝${NC}"
        echo ""
        FAILED_SCRIPTS+=("$display_name")
        SCRIPT_FAILED=true
    fi
}

###############################################################################
### Interactive Configuration
###############################################################################

echo ""
echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║                     Peter Sharpe's Linux Setup Script                         ║${NC}"
echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if prompt_yn "Dry run (preview changes without making them)? [y/N]" "N"; then
    DRY_RUN=true
else
    DRY_RUN=false
fi

if prompt_yn "Headless mode (skip GUI packages)? [y/N]" "N"; then
    HEADLESS="Y"
else
    HEADLESS="N"
fi

if prompt_yn "Install snap applications? [Y/n]" "Y"; then
    INSTALL_SNAPS="Y"
else
    INSTALL_SNAPS="N"
fi

GIT_NAME=$(prompt_input "Git user name" "Peter Sharpe")
GIT_EMAIL=$(prompt_input "Git email" "peterdsharpe@gmail.com")

### Detect and configure sudo access
if [[ $EUID -eq 0 ]]; then
    # Already running as root
    HAS_SUDO=true
    print_info "Running as root"
elif sudo -n true 2>/dev/null; then
    # Sudo available (cached credentials or NOPASSWD configured)
    HAS_SUDO=true
    print_info "Sudo access available"
    # Start keepalive to prevent credential timeout mid-script
    (while true; do sudo -v; sleep 60; done) &
    SUDO_KEEPALIVE_PID=$!
    trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null" EXIT
else
    # Not elevated - ask user what they want to do
    echo ""
    print_warning "Not running with sudo privileges."
    echo "    1) Authenticate with sudo (full installation)"
    echo "    2) Proceed without sudo (limited functionality)"
    echo ""
    if prompt_yn "Authenticate with sudo? [Y/n]" "Y"; then
        # Attempt sudo authentication
        echo ""
        if sudo -v; then
            HAS_SUDO=true
            print_success "Sudo authentication successful"
            # Keep sudo credentials alive in background
            (while true; do sudo -v; sleep 60; done) &
            SUDO_KEEPALIVE_PID=$!
            trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null" EXIT
        else
            print_error "Sudo authentication failed"
            if prompt_yn "Continue without sudo (limited functionality)? [Y/n]" "Y"; then
                HAS_SUDO=false
            else
                exit 1
            fi
        fi
    else
        HAS_SUDO=false
        print_info "Proceeding without sudo"
    fi
fi

# Export configuration for child scripts
export DRY_RUN HEADLESS INSTALL_SNAPS GIT_NAME GIT_EMAIL HAS_SUDO
export ORCHESTRATED=true

echo ""
print_info "Configuration: HEADLESS=$HEADLESS, INSTALL_SNAPS=$INSTALL_SNAPS, DRY_RUN=$DRY_RUN, HAS_SUDO=$HAS_SUDO"
print_info "Git: $GIT_NAME <$GIT_EMAIL>"

###############################################################################
### Parse Manifest and Execute Scripts
###############################################################################

MANIFEST_FILE="$SCRIPT_DIR/install_scripts/manifest.conf"
INSTALL_SCRIPTS_DIR="$SCRIPT_DIR/install_scripts"

if [[ ! -f "$MANIFEST_FILE" ]]; then
    print_error "Manifest file not found: $MANIFEST_FILE"
    exit 1
fi

# Parse INI-style manifest (pure bash, no external dependencies)
# Outputs lines in format: SECTION:name or SCRIPT:path
parse_manifest() {
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" == \#* ]] && continue
        
        # Section header: [Section Name]
        if [[ "$line" == \[*\] ]]; then
            # Extract section name by removing brackets
            local section="${line#[}"
            section="${section%]}"
            echo "SECTION:$section"
        else
            # Script path
            echo "SCRIPT:$line"
        fi
    done < "$MANIFEST_FILE"
}

# Cache parsed manifest
PARSED_MANIFEST=$(parse_manifest)
if [[ -z "$PARSED_MANIFEST" ]]; then
    print_error "Failed to parse manifest file"
    exit 1
fi

###############################################################################
### Manifest Validation
###############################################################################

# Collect scripts referenced in manifest
declare -a MANIFEST_SCRIPTS=()
while IFS= read -r line; do
    if [[ "$line" == SCRIPT:* ]]; then
        MANIFEST_SCRIPTS+=("${line#SCRIPT:}")
    fi
done <<< "$PARSED_MANIFEST"

# Find all .sh files in install_scripts/
declare -a DISK_SCRIPTS=()
while IFS= read -r -d '' file; do
    # Get path relative to install_scripts/
    rel_path="${file#$INSTALL_SCRIPTS_DIR/}"
    DISK_SCRIPTS+=("$rel_path")
done < <(find "$INSTALL_SCRIPTS_DIR" -name "*.sh" -type f -print0 | sort -z)

# Check for scripts in manifest that don't exist on disk
declare -a MISSING_ON_DISK=()
for script in "${MANIFEST_SCRIPTS[@]}"; do
    if [[ ! -f "$INSTALL_SCRIPTS_DIR/$script" ]]; then
        MISSING_ON_DISK+=("$script")
    fi
done

# Check for scripts on disk that aren't in manifest
declare -a NOT_IN_MANIFEST=()
for script in "${DISK_SCRIPTS[@]}"; do
    found=false
    for manifest_script in "${MANIFEST_SCRIPTS[@]}"; do
        if [[ "$script" == "$manifest_script" ]]; then
            found=true
            break
        fi
    done
    if [[ "$found" == false ]]; then
        NOT_IN_MANIFEST+=("$script")
    fi
done

# Display validation warnings
validation_failed=false

if [[ ${#MISSING_ON_DISK[@]} -gt 0 ]]; then
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  WARNING: Scripts in manifest that don't exist on disk                       ║${NC}"
    echo -e "${RED}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    for script in "${MISSING_ON_DISK[@]}"; do
        echo -e "${RED}║${NC}   $script"
    done
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    validation_failed=true
fi

if [[ ${#NOT_IN_MANIFEST[@]} -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  WARNING: Scripts on disk not referenced in manifest                         ║${NC}"
    echo -e "${YELLOW}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    for script in "${NOT_IN_MANIFEST[@]}"; do
        echo -e "${YELLOW}║${NC}   $script"
    done
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    validation_failed=true
fi

if [[ "$validation_failed" == true ]]; then
    echo ""
    if ! prompt_yn "Continue anyway? [y/N]" "N"; then
        print_error "Aborting due to manifest validation errors"
        exit 1
    fi
    echo ""
fi

###############################################################################
### Execute Scripts
###############################################################################

while IFS= read -r line; do
    # Handle section headers
    if [[ "$line" == SECTION:* ]]; then
        section_name="${line#SECTION:}"
        print_header "$section_name"
        continue
    fi
    
    # Handle script entries
    if [[ "$line" == SCRIPT:* ]]; then
        script_rel_path="${line#SCRIPT:}"
        script_full_path="$SCRIPT_DIR/install_scripts/$script_rel_path"
        
        if [[ ! -f "$script_full_path" ]]; then
            print_warning "Script not found: $script_rel_path"
            SKIPPED_SCRIPTS+=("$script_rel_path (not found)")
            continue
        fi
        
        if [[ ! -x "$script_full_path" ]]; then
            print_warning "Script not executable: $script_rel_path"
            SKIPPED_SCRIPTS+=("$script_rel_path (not executable)")
            continue
        fi
        
        # Extract display name from script filename (remove .sh and path)
        display_name=$(basename "$script_rel_path" .sh)
        # Convert underscores to spaces and capitalize
        display_name=$(echo "$display_name" | tr '_' ' ' | sed 's/\b\(.\)/\u\1/g')
        
        # Run the script with framed output
        run_framed "$display_name" "$script_full_path"
    fi
done <<< "$PARSED_MANIFEST"

###############################################################################
### Summary
###############################################################################

print_header "Setup Complete!"

echo ""
if [[ ${#COMPLETED_SCRIPTS[@]} -gt 0 ]]; then
    print_success "Completed: ${#COMPLETED_SCRIPTS[@]} components"
fi

if [[ ${#SKIPPED_SCRIPTS[@]} -gt 0 ]]; then
    print_warning "Skipped: ${#SKIPPED_SCRIPTS[@]} components"
    for script in "${SKIPPED_SCRIPTS[@]}"; do
        echo "    - $script"
    done
fi

if [[ ${#FAILED_SCRIPTS[@]} -gt 0 ]]; then
    print_error "Failed: ${#FAILED_SCRIPTS[@]} components"
    for script in "${FAILED_SCRIPTS[@]}"; do
        echo "    - $script"
    done
fi

echo ""
if [[ "$HAS_SUDO" == false ]]; then
    print_warning "Ran in limited mode (no sudo) - some components may have been skipped"
    echo ""
fi

# GitHub CLI auth reminder
if command -v gh &> /dev/null; then
    print_info "Authenticate GitHub CLI:"
    echo "    gh auth login"
    echo ""
fi

print_info "Set up VS Code / Cursor to use PeterProfile as the default profile"
echo "    Find at https://gist.github.com/peterdsharpe"
echo ""

if [[ "$HAS_SUDO" == true ]]; then
    print_warning "Log out and back in to use zsh as your default shell"
    echo ""
fi

# Exit with failure if any step failed
if [[ "$SCRIPT_FAILED" == true ]]; then
    print_error "Some components failed - review output above"
    exit 1
fi
