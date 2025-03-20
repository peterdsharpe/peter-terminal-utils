@echo off
echo Installing cmdrc.bat as AutoRun for Command Processor...

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: This script requires administrator privileges.
    echo Please run this script as administrator.
    pause
    exit /b 1
)

:: Get the current directory and check if cmdrc.bat exists
set "CURRENT_DIR=%~dp0"
set "CMDRC_PATH=%CURRENT_DIR%cmdrc.bat"

if not exist "%CMDRC_PATH%" (
    echo Error: cmdrc.bat not found in the current directory.
    echo Expected path: %CMDRC_PATH%
    pause
    exit /b 1
)

:: Set the registry key with the dynamic path
reg add "HKLM\SOFTWARE\Microsoft\Command Processor" /v AutoRun /t REG_SZ /d "%CMDRC_PATH%" /f

if %errorlevel% equ 0 (
    echo Registry key set successfully.
    echo Command Prompt will now run cmdrc.bat on startup.
    echo Path: %CMDRC_PATH%
) else (
    echo Failed to set registry key.
)

pause
