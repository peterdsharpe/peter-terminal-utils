@echo off
setlocal EnableDelayedExpansion

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: WSL Setup Script
::: Installs WSL2 with Ubuntu and runs linux/setup.sh inside it
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Get script directory
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "LINUX_DIR=%SCRIPT_DIR%\..\linux"

:: Color codes
set "ESC="
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "BLUE=%ESC%[94m"
set "CYAN=%ESC%[96m"
set "BOLD=%ESC%[1m"
set "NC=%ESC%[0m"

echo.
echo %BOLD%%CYAN%+-------------------------------------------------------------------------------+%NC%
echo %BOLD%%CYAN%^|                         WSL Setup Script                                     ^|%NC%
echo %BOLD%%CYAN%+-------------------------------------------------------------------------------+%NC%
echo.

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: Admin Check
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%x%NC% This script requires administrator privileges.
    echo.
    echo   Please right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo %GREEN%√%NC% Running with administrator privileges
echo.

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: Check if WSL is already installed
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

wsl --status >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%√%NC% WSL is already installed
    
    :: Check for Ubuntu
    wsl -l -q 2>nul | findstr /i "ubuntu" >nul 2>&1
    if %errorlevel% equ 0 (
        echo %GREEN%√%NC% Ubuntu distribution found
        goto :run_setup
    ) else (
        echo %YELLOW%!%NC% Ubuntu not found, will install...
        goto :install_ubuntu
    )
) else (
    echo %CYAN%^>%NC% WSL not installed, will install WSL2 with Ubuntu...
    goto :install_wsl
)

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: Install WSL
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:install_wsl
echo.
echo %CYAN%^>%NC% Installing WSL2 (this may take a few minutes)...
echo.

:: Install WSL with Ubuntu as default
wsl --install -d Ubuntu

if %errorlevel% equ 0 (
    echo.
    echo %GREEN%√%NC% WSL installation initiated
    echo.
    echo %YELLOW%!%NC% IMPORTANT: A restart is required to complete WSL installation.
    echo.
    echo   After restarting:
    echo   1. Open Ubuntu from the Start menu to complete first-time setup
    echo   2. Create your Linux username and password when prompted
    echo   3. Run this script again to continue with Linux setup
    echo.
    set /p "RESTART_NOW=Restart now? [Y/n]: "
    if /i not "!RESTART_NOW!"=="n" (
        if /i not "!RESTART_NOW!"=="no" (
            shutdown /r /t 10 /c "Restarting to complete WSL installation..."
            echo.
            echo %BLUE%i%NC% Computer will restart in 10 seconds...
            echo     Press Ctrl+C and then Y to cancel.
        )
    )
) else (
    echo %RED%x%NC% Failed to install WSL
    echo.
    echo   Try running manually: wsl --install -d Ubuntu
    echo.
)
pause
exit /b 0

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: Install Ubuntu (WSL already installed)
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:install_ubuntu
echo.
echo %CYAN%^>%NC% Installing Ubuntu distribution...
echo.

wsl --install -d Ubuntu --no-launch

if %errorlevel% equ 0 (
    echo.
    echo %GREEN%√%NC% Ubuntu installed
    echo.
    echo %YELLOW%!%NC% Opening Ubuntu to complete first-time setup...
    echo     Create your Linux username and password when prompted.
    echo.
    echo   After setup completes, close the Ubuntu window and run this script again.
    echo.
    
    :: Launch Ubuntu for first-time setup
    start ubuntu
    pause
    exit /b 0
) else (
    echo %RED%x%NC% Failed to install Ubuntu
    pause
    exit /b 1
)

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: Run Linux Setup
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:run_setup
echo.
echo %CYAN%^>%NC% Checking for linux/setup.sh...

:: Convert Windows path to WSL path
for /f "tokens=*" %%a in ('wsl wslpath -a "%LINUX_DIR%"') do set "WSL_LINUX_DIR=%%a"

:: Check if setup.sh exists
wsl test -f "%WSL_LINUX_DIR%/setup.sh"
if %errorlevel% neq 0 (
    echo %RED%x%NC% setup.sh not found at: %LINUX_DIR%
    echo.
    echo   Expected: %WSL_LINUX_DIR%/setup.sh
    echo.
    pause
    exit /b 1
)

echo %GREEN%√%NC% Found setup.sh
echo.

:: Prompt before running
set /p "RUN_SETUP=Run linux/setup.sh in WSL now? [Y/n]: "
if /i "%RUN_SETUP%"=="n" goto :skip_setup
if /i "%RUN_SETUP%"=="no" goto :skip_setup

echo.
echo %CYAN%^>%NC% Running linux/setup.sh in WSL...
echo %BLUE%i%NC% This will configure your WSL Ubuntu environment.
echo.
echo ═══════════════════════════════════════════════════════════════════════════════
echo.

:: Run setup.sh in WSL
:: Using bash explicitly and cd to the directory first
wsl bash -c "cd '%WSL_LINUX_DIR%' && chmod +x setup.sh && ./setup.sh"

echo.
echo ═══════════════════════════════════════════════════════════════════════════════
echo.

if %errorlevel% equ 0 (
    echo %GREEN%√%NC% Linux setup completed successfully
) else (
    echo %YELLOW%!%NC% Linux setup completed with some warnings/errors (see above)
)

goto :configure_integration

:skip_setup
echo %YELLOW%o%NC% Skipped linux/setup.sh

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: Configure Integration
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:configure_integration
echo.
echo %CYAN%^>%NC% Configuring Windows/WSL integration...

:: Set WSL2 as default
wsl --set-default-version 2 >nul 2>&1
echo %GREEN%√%NC% WSL2 set as default version

:: Set Ubuntu as default distro
wsl --set-default Ubuntu >nul 2>&1
echo %GREEN%√%NC% Ubuntu set as default distribution

:: Enable systemd (if not already enabled)
echo %CYAN%^>%NC% Enabling systemd in WSL...
wsl bash -c "if [ ! -f /etc/wsl.conf ] || ! grep -q 'systemd=true' /etc/wsl.conf 2>/dev/null; then echo -e '[boot]\nsystemd=true' | sudo tee /etc/wsl.conf > /dev/null && echo 'Enabled systemd'; else echo 'Systemd already enabled'; fi"

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: Summary
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

echo.
echo %BOLD%%BLUE%═══════════════════════════════════════════════════════════════════════════════%NC%
echo %BOLD%%BLUE%  WSL Setup Complete!%NC%
echo %BOLD%%BLUE%═══════════════════════════════════════════════════════════════════════════════%NC%
echo.

echo %GREEN%√%NC% WSL2 with Ubuntu is ready to use.
echo.
echo %BLUE%i%NC% Quick commands:
echo     wsl                    - Open WSL in current directory
echo     wsl ~                  - Open WSL in Linux home directory
echo     wsl [command]          - Run a command in WSL
echo.
echo %BLUE%i%NC% Windows Terminal:
echo     Ubuntu should appear as a profile in Windows Terminal.
echo     Set your preferred font to "FiraCode Nerd Font" for icons.
echo.
echo %BLUE%i%NC% VS Code / Cursor:
echo     Install the "WSL" extension to develop inside Linux.
echo     Use "code ." or "cursor ." from WSL to open the current folder.
echo.

pause
exit /b 0

