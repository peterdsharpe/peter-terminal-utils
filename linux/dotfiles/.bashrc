# shellcheck shell=bash
# Peter's .bashrc configuration
# Managed by peter-terminal-utils - do not edit directly

# Exit early if not running interactively (e.g., scp, rsync)
[[ $- != *i* ]] && return

# Source system-wide bashrc if present (preserves distro/cluster defaults)
# On HPC clusters (RHEL/CentOS), /etc/bashrc sets up the module system (lmod)
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
elif [ -f /etc/bash.bashrc ]; then
    . /etc/bash.bashrc
fi

###############################################################################
### Shared shell configuration
###############################################################################

# Common aliases, PATH, env vars, tool inits, functions
if [ -f "$HOME/.shell_common" ]; then
    . "$HOME/.shell_common"
fi

###############################################################################
### Bash options
###############################################################################

# Check window size after each command and update LINES/COLUMNS
shopt -s checkwinsize

# Correct minor typos in cd directory names
shopt -s cdspell

# Allow ** glob to match recursively (e.g., ls **/*.py)
shopt -s globstar 2>/dev/null

# Append to history file rather than overwriting it
shopt -s histappend

# Save multiline commands as single history entries
shopt -s cmdhist

###############################################################################
### History configuration
###############################################################################

HISTSIZE=50000
HISTFILESIZE=50000
HISTCONTROL=ignoredups:ignorespace  # Ignore duplicate and space-prefixed commands
HISTTIMEFORMAT="%F %T "            # Timestamp each entry

###############################################################################
### Prompt
###############################################################################

# Git branch for prompt (uses __git_ps1 if available, fallback otherwise)
_prompt_git_info() {
    if command -v __git_ps1 &>/dev/null; then
        __git_ps1 " (%s)"
    else
        local branch
        branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
        [ -n "$branch" ] && echo " ($branch)"
    fi
}

# Two-line prompt: user@host:dir (branch)
# $ indicator is green on success, red on failure
PROMPT_COMMAND='_prompt_exit=$?'
# shellcheck disable=SC2154  # _prompt_exit is assigned by PROMPT_COMMAND before PS1 evaluates
PS1='\[\e[0;36m\]\u@\h\[\e[0m\]:\[\e[0;34m\]\w\[\e[1;33m\]$(_prompt_git_info)\[\e[0m\]\n$([ $_prompt_exit -eq 0 ] && echo "\[\e[0;32m\]" || echo "\[\e[0;31m\]")\$\[\e[0m\] '

###############################################################################
### Bash completions
###############################################################################

# Enable programmable completion (if not already done by system bashrc)
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

###############################################################################
### Local overrides
###############################################################################

# Source machine-specific config (module loads, conda init, etc.)
# Create this file for any per-machine customization that shouldn't be tracked
if [ -f "$HOME/.bashrc.local" ]; then
    . "$HOME/.bashrc.local"
fi
. "$HOME/.cargo/env"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
