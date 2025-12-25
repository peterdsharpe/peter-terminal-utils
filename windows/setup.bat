@echo off
setlocal EnableDelayedExpansion

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: Peter Sharpe's Windows Setup Script
::: Mirrors functionality of linux/setup.sh for Windows environments
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Get script directory
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: Color codes for Windows 10+ (ANSI escape sequences)
set "ESC="
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "BLUE=%ESC%[94m"
set "CYAN=%ESC%[96m"
set "BOLD=%ESC%[1m"
set "DIM=%ESC%[2m"
set "NC=%ESC%[0m"

:: Track failures
set "SCRIPT_FAILED=0"
set "DRY_RUN=0"
set "HAS_ADMIN=0"

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: Logging Helpers
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

goto :skip_functions

:print_header
echo.
echo %BOLD%%BLUE%===============================================================================%NC%
echo %BOLD%%BLUE%  %~1%NC%
echo %BOLD%%BLUE%===============================================================================%NC%
goto :eof

:print_step
echo %CYAN%^>%NC% %~1
goto :eof

:print_success
echo %GREEN%√%NC% %~1
goto :eof

:print_skip
echo %YELLOW%o%NC% %~1 (skipped)
goto :eof

:print_warning
echo %YELLOW%!%NC% %~1
goto :eof

:print_error
echo %RED%x%NC% %~1
set "SCRIPT_FAILED=1"
goto :eof

:print_info
echo %BLUE%i%NC% %~1
goto :eof

:skip_functions

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: Banner and Interactive Configuration
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

echo.
echo %BOLD%%CYAN%+-------------------------------------------------------------------------------+%NC%
echo %BOLD%%CYAN%^|                     Peter Sharpe's Windows Setup Script                      ^|%NC%
echo %BOLD%%CYAN%+-------------------------------------------------------------------------------+%NC%
echo.

:: Dry run prompt
set /p "DRY_RUN_INPUT=Dry run (preview changes without making them)? [y/N]: "
if /i "%DRY_RUN_INPUT%"=="y" set "DRY_RUN=1"
if /i "%DRY_RUN_INPUT%"=="yes" set "DRY_RUN=1"

:: Install GUI apps prompt
set "INSTALL_GUI=1"
set /p "GUI_INPUT=Install GUI applications (Obsidian, Signal, etc.)? [Y/n]: "
if /i "%GUI_INPUT%"=="n" set "INSTALL_GUI=0"
if /i "%GUI_INPUT%"=="no" set "INSTALL_GUI=0"

:: Install Scoop prompt (for tools not in winget)
set "INSTALL_SCOOP=1"
set /p "SCOOP_INPUT=Install Scoop package manager (for eza, delta, etc.)? [Y/n]: "
if /i "%SCOOP_INPUT%"=="n" set "INSTALL_SCOOP=0"
if /i "%SCOOP_INPUT%"=="no" set "INSTALL_SCOOP=0"

:: Git configuration
set "GIT_NAME=Peter Sharpe"
set /p "GIT_NAME=Git user name [%GIT_NAME%]: " || set "GIT_NAME=Peter Sharpe"
if "%GIT_NAME%"=="" set "GIT_NAME=Peter Sharpe"

set "GIT_EMAIL=peterdsharpe@gmail.com"
set /p "GIT_EMAIL=Git email [%GIT_EMAIL%]: " || set "GIT_EMAIL=peterdsharpe@gmail.com"
if "%GIT_EMAIL%"=="" set "GIT_EMAIL=peterdsharpe@gmail.com"

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% equ 0 (
    set "HAS_ADMIN=1"
    call :print_info "Running with administrator privileges"
) else (
    call :print_warning "Running without administrator privileges (some features limited)"
)

echo.
call :print_info "Configuration: DRY_RUN=%DRY_RUN%, INSTALL_GUI=%INSTALL_GUI%, INSTALL_SCOOP=%INSTALL_SCOOP%, HAS_ADMIN=%HAS_ADMIN%"
call :print_info "Git: %GIT_NAME% ^<%GIT_EMAIL%^>"
echo.

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: Package Manager Setup
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

call :print_header "Package Managers"

:: Check for winget
where winget >nul 2>&1
if %errorlevel% neq 0 (
    call :print_error "winget not found. Please install App Installer from Microsoft Store."
    call :print_info "https://apps.microsoft.com/store/detail/app-installer/9NBLGGH4NNS1"
    echo.
    pause
    exit /b 1
) else (
    call :print_success "winget is available"
)

:: Install Scoop if requested
if "%INSTALL_SCOOP%"=="1" (
    where scoop >nul 2>&1
    if %errorlevel% neq 0 (
        if "%DRY_RUN%"=="1" (
            call :print_info "[DRY RUN] Would install Scoop package manager"
        ) else (
            call :print_step "Installing Scoop package manager"
            powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; irm get.scoop.sh | iex"
            if %errorlevel% equ 0 (
                call :print_success "Scoop installed"
                :: Add extras bucket for more packages
                call scoop bucket add extras >nul 2>&1
                call scoop bucket add nerd-fonts >nul 2>&1
            ) else (
                call :print_error "Failed to install Scoop"
            )
        )
    ) else (
        call :print_skip "Scoop already installed"
        :: Ensure buckets are added
        call scoop bucket add extras >nul 2>&1
        call scoop bucket add nerd-fonts >nul 2>&1
    )
)

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: CLI Tools Installation
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

call :print_header "CLI Tools"

:: Helper for winget install (checks if already installed)
:: Usage: call :winget_install "Package.Id" "display name"
goto :skip_winget_install
:winget_install
set "PKG_ID=%~1"
set "PKG_NAME=%~2"
winget list --id "%PKG_ID%" >nul 2>&1
if %errorlevel% equ 0 (
    call :print_skip "%PKG_NAME% already installed"
) else (
    if "%DRY_RUN%"=="1" (
        call :print_info "[DRY RUN] Would install %PKG_NAME%"
    ) else (
        call :print_step "Installing %PKG_NAME%"
        winget install --id "%PKG_ID%" --silent --accept-package-agreements --accept-source-agreements >nul 2>&1
        if %errorlevel% equ 0 (
            call :print_success "%PKG_NAME% installed"
        ) else (
            call :print_error "Failed to install %PKG_NAME%"
        )
    )
)
goto :eof
:skip_winget_install

:: Helper for scoop install
:: Usage: call :scoop_install "package" "display name"
goto :skip_scoop_install
:scoop_install
set "PKG=%~1"
set "PKG_NAME=%~2"
if "%INSTALL_SCOOP%"=="0" (
    call :print_skip "%PKG_NAME% (Scoop disabled)"
    goto :eof
)
where scoop >nul 2>&1
if %errorlevel% neq 0 (
    call :print_skip "%PKG_NAME% (Scoop not available)"
    goto :eof
)
scoop list %PKG% >nul 2>&1
if %errorlevel% equ 0 (
    call :print_skip "%PKG_NAME% already installed"
) else (
    if "%DRY_RUN%"=="1" (
        call :print_info "[DRY RUN] Would install %PKG_NAME% via Scoop"
    ) else (
        call :print_step "Installing %PKG_NAME% via Scoop"
        scoop install %PKG% >nul 2>&1
        if %errorlevel% equ 0 (
            call :print_success "%PKG_NAME% installed"
        ) else (
            call :print_error "Failed to install %PKG_NAME%"
        )
    )
)
goto :eof
:skip_scoop_install

:: Git (essential - install first)
call :winget_install "Git.Git" "Git"

:: GitHub CLI
call :winget_install "GitHub.cli" "GitHub CLI (gh)"

:: Core CLI tools available via winget
call :winget_install "BurntSushi.ripgrep.MSVC" "ripgrep (rg)"
call :winget_install "sharkdp.fd" "fd"
call :winget_install "sharkdp.bat" "bat"
call :winget_install "junegunn.fzf" "fzf"
call :winget_install "ajeetdsouza.zoxide" "zoxide"
call :winget_install "Neovim.Neovim" "Neovim"
call :winget_install "JesseDuffield.lazygit" "lazygit"
call :winget_install "stedolan.jq" "jq"
call :winget_install "cURL.cURL" "curl"
call :winget_install "GNU.Wget2" "wget"

:: Tools better installed via Scoop (not in winget or better Scoop version)
call :scoop_install "eza" "eza (modern ls)"
call :scoop_install "delta" "delta (git diff pager)"
call :scoop_install "bottom" "bottom (btm - system monitor)"

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: Development Tools
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

call :print_header "Development Tools"

:: uv (Python)
where uv >nul 2>&1
if %errorlevel% equ 0 (
    call :print_skip "uv already installed"
) else (
    if "%DRY_RUN%"=="1" (
        call :print_info "[DRY RUN] Would install uv (Python package manager)"
    ) else (
        call :print_step "Installing uv (Python package manager)"
        powershell -NoProfile -ExecutionPolicy ByPass -Command "irm https://astral.sh/uv/install.ps1 | iex" >nul 2>&1
        if %errorlevel% equ 0 (
            call :print_success "uv installed"
        ) else (
            call :print_error "Failed to install uv"
        )
    )
)

:: Rust
where rustup >nul 2>&1
if %errorlevel% equ 0 (
    call :print_skip "Rust already installed"
) else (
    if "%DRY_RUN%"=="1" (
        call :print_info "[DRY RUN] Would install Rust"
    ) else (
        call :print_step "Installing Rust"
        winget install --id Rustlang.Rustup --silent --accept-package-agreements --accept-source-agreements >nul 2>&1
        if %errorlevel% equ 0 (
            call :print_success "Rust installed"
        ) else (
            call :print_error "Failed to install Rust"
        )
    )
)

:: Docker Desktop
where docker >nul 2>&1
if %errorlevel% equ 0 (
    call :print_skip "Docker already installed"
) else (
    if "%DRY_RUN%"=="1" (
        call :print_info "[DRY RUN] Would install Docker Desktop"
    ) else (
        call :print_step "Installing Docker Desktop"
        winget install --id Docker.DockerDesktop --silent --accept-package-agreements --accept-source-agreements >nul 2>&1
        if %errorlevel% equ 0 (
            call :print_success "Docker Desktop installed"
            call :print_warning "Log out and back in, then start Docker Desktop"
        ) else (
            call :print_error "Failed to install Docker Desktop"
        )
    )
)

:: Cursor IDE
where cursor >nul 2>&1
if %errorlevel% equ 0 (
    call :print_skip "Cursor already installed"
) else (
    call :winget_install "Anysphere.Cursor" "Cursor IDE"
)

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: GUI Applications
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

if "%INSTALL_GUI%"=="1" (
    call :print_header "GUI Applications"

    call :winget_install "Microsoft.WindowsTerminal" "Windows Terminal"
    call :winget_install "Microsoft.VisualStudioCode" "VS Code"
    call :winget_install "Mozilla.Firefox" "Firefox"
    call :winget_install "Obsidian.Obsidian" "Obsidian"
    call :winget_install "OpenWhisperSystems.Signal" "Signal"
    call :winget_install "VideoLAN.VLC" "VLC"
    call :winget_install "TheDocumentFoundation.LibreOffice" "LibreOffice"
    call :winget_install "Inkscape.Inkscape" "Inkscape"
    call :winget_install "Valve.Steam" "Steam"
    call :winget_install "Zotero.Zotero" "Zotero"
) else (
    call :print_header "GUI Applications"
    call :print_skip "GUI application installation disabled"
)

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: Fonts
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

call :print_header "Fonts"

:: Install fonts via Scoop (requires nerd-fonts bucket)
if "%INSTALL_SCOOP%"=="1" (
    where scoop >nul 2>&1
    if %errorlevel% equ 0 (
        :: FiraCode Nerd Font
        scoop list FiraCode-NF >nul 2>&1
        if %errorlevel% equ 0 (
            call :print_skip "FiraCode Nerd Font already installed"
        ) else (
            if "%DRY_RUN%"=="1" (
                call :print_info "[DRY RUN] Would install FiraCode Nerd Font"
            ) else (
                call :print_step "Installing FiraCode Nerd Font"
                scoop install nerd-fonts/FiraCode-NF >nul 2>&1
                if %errorlevel% equ 0 (
                    call :print_success "FiraCode Nerd Font installed"
                ) else (
                    call :print_error "Failed to install FiraCode Nerd Font"
                )
            )
        )
        
        :: Symbols Nerd Font
        scoop list NerdFontsSymbolsOnly >nul 2>&1
        if %errorlevel% equ 0 (
            call :print_skip "Symbols Nerd Font already installed"
        ) else (
            if "%DRY_RUN%"=="1" (
                call :print_info "[DRY RUN] Would install Symbols Nerd Font"
            ) else (
                call :print_step "Installing Symbols Nerd Font"
                scoop install nerd-fonts/NerdFontsSymbolsOnly >nul 2>&1
                if %errorlevel% equ 0 (
                    call :print_success "Symbols Nerd Font installed"
                ) else (
                    call :print_error "Failed to install Symbols Nerd Font"
                )
            )
        )
    ) else (
        call :print_skip "Fonts (Scoop not available)"
    )
) else (
    call :print_skip "Fonts (Scoop disabled)"
)

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: SSH Setup
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

call :print_header "SSH Setup"

if exist "%USERPROFILE%\.ssh\id_ed25519" (
    call :print_skip "SSH key already exists"
) else (
    if "%DRY_RUN%"=="1" (
        call :print_info "[DRY RUN] Would generate SSH key pair"
    ) else (
        call :print_step "Generating SSH key pair"
        if not exist "%USERPROFILE%\.ssh" mkdir "%USERPROFILE%\.ssh"
        ssh-keygen -t ed25519 -C "%GIT_EMAIL%" -f "%USERPROFILE%\.ssh\id_ed25519" -N "" >nul 2>&1
        if %errorlevel% equ 0 (
            call :print_success "SSH key pair generated"
        ) else (
            call :print_error "Failed to generate SSH key pair"
        )
    )
)

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: Git Configuration
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

call :print_header "Git Configuration"

if "%DRY_RUN%"=="1" (
    call :print_info "[DRY RUN] Would configure git settings"
) else (
    call :print_step "Configuring git"
    
    :: Basic settings
    git config --global user.name "%GIT_NAME%"
    git config --global user.email "%GIT_EMAIL%"
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global core.editor "nvim"
    git config --global push.autoSetupRemote true
    git config --global fetch.prune true
    
    :: Aliases
    git config --global alias.st status
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.lg "log --oneline --graph --decorate"
    git config --global alias.amend "commit --amend --no-edit"
    git config --global alias.last "log -1 HEAD --stat"
    
    :: Delta integration (if delta is installed)
    where delta >nul 2>&1
    if %errorlevel% equ 0 (
        git config --global core.pager delta
        git config --global interactive.diffFilter "delta --color-only"
        git config --global delta.navigate true
        git config --global delta.side-by-side true
    )
    
    :: Better merge/rebase defaults
    git config --global merge.conflictstyle diff3
    git config --global rebase.autoStash true
    
    :: Initialize git-lfs
    where git-lfs >nul 2>&1
    if %errorlevel% equ 0 (
        git lfs install >nul 2>&1
    )
    
    call :print_success "Git configured"
)

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: Shell Configuration
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

call :print_header "Shell Configuration"

:: Install PowerShell profile
set "PS_PROFILE_DIR=%USERPROFILE%\Documents\PowerShell"
set "PS_PROFILE=%PS_PROFILE_DIR%\Microsoft.PowerShell_profile.ps1"
set "SOURCE_PROFILE=%SCRIPT_DIR%\profile.ps1"

if exist "%SOURCE_PROFILE%" (
    if "%DRY_RUN%"=="1" (
        call :print_info "[DRY RUN] Would install PowerShell profile"
    ) else (
        call :print_step "Installing PowerShell profile"
        if not exist "%PS_PROFILE_DIR%" mkdir "%PS_PROFILE_DIR%"
        
        :: Check if profile already sources our file
        if exist "%PS_PROFILE%" (
            findstr /C:"peter-terminal-utils" "%PS_PROFILE%" >nul 2>&1
            if %errorlevel% equ 0 (
                call :print_skip "PowerShell profile already configured"
                goto :skip_ps_profile
            )
        )
        
        :: Add sourcing line to profile
        echo. >> "%PS_PROFILE%"
        echo # Peter's terminal utilities >> "%PS_PROFILE%"
        echo . "%SOURCE_PROFILE%" >> "%PS_PROFILE%"
        call :print_success "PowerShell profile installed"
    )
)
:skip_ps_profile

:: Install cmdrc (for CMD users)
if "%DRY_RUN%"=="1" (
    call :print_info "[DRY RUN] Would check cmdrc.bat installation"
) else (
    reg query "HKCU\SOFTWARE\Microsoft\Command Processor" /v AutoRun >nul 2>&1
    if %errorlevel% equ 0 (
        call :print_skip "CMD AutoRun already configured"
    ) else (
        call :print_step "Configuring CMD AutoRun (cmdrc.bat)"
        reg add "HKCU\SOFTWARE\Microsoft\Command Processor" /v AutoRun /t REG_SZ /d "%SCRIPT_DIR%\cmdrc.bat" /f >nul 2>&1
        if %errorlevel% equ 0 (
            call :print_success "CMD AutoRun configured"
        ) else (
            call :print_warning "Failed to configure CMD AutoRun (may need admin)"
        )
    )
)

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: Python Tools (via uv)
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

call :print_header "Python Tools"

:: Refresh PATH to include uv
set "PATH=%USERPROFILE%\.local\bin;%USERPROFILE%\.cargo\bin;%PATH%"

where uv >nul 2>&1
if %errorlevel% equ 0 (
    if "%DRY_RUN%"=="1" (
        call :print_info "[DRY RUN] Would install Python tools via uv"
    ) else (
        call :print_step "Installing Python tools via uv"
        
        uv tool install ruff >nul 2>&1
        uv tool install ty >nul 2>&1
        uv tool install httpie >nul 2>&1
        uv tool install pre-commit >nul 2>&1
        uv tool install yt-dlp >nul 2>&1
        uv tool install rich-cli >nul 2>&1
        uv tool install jupyterlab >nul 2>&1
        uv tool install pytest >nul 2>&1
        uv tool upgrade --all >nul 2>&1
        
        call :print_success "Python tools installed"
    )
) else (
    call :print_skip "Python tools (uv not available)"
)

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: Summary
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

call :print_header "Setup Complete!"

echo.
call :print_success "All done! Here's what to do next:"
echo.

:: GitHub CLI auth reminder
where gh >nul 2>&1
if %errorlevel% equ 0 (
    call :print_info "Authenticate GitHub CLI:"
    echo     gh auth login
    echo.
)

call :print_info "Set up VS Code / Cursor to use PeterProfile as the default profile"
echo     Find at https://gist.github.com/peterdsharpe
echo.

call :print_info "To set up WSL with your Linux configuration, run:"
echo     %SCRIPT_DIR%\setup_wsl.bat
echo.

if "%SCRIPT_FAILED%"=="1" (
    call :print_error "Some steps failed - review output above"
    pause
    exit /b 1
)

pause
exit /b 0

