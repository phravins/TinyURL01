@echo off
:: install.bat — Windows installer for shortener CLI
:: Must be run as Administrator

setlocal
set SCRIPT_DIR=%~dp0
set INSTALL_DIR=%PROGRAMFILES%\shortener-cli

echo.
echo  TinyURL Local Installer for Windows
echo.

:: Check for Admin
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo  ❌ ERROR: This script MUST be run as Administrator.
    echo  To fix this: Right-click your Terminal/PowerShell and select 'Run as Administrator'.
    exit /b 1
)

:: Check Erlang/escript is available
where escript >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo  ERROR: 'escript' not found on PATH.
    echo  Please install Erlang from https://www.erlang.org/downloads first.
    exit /b 1
)

:: Create install directory
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

:: Copy files
echo  ↓ Copying files...
copy /Y "%SCRIPT_DIR%shortener_cli" "%INSTALL_DIR%\shortener_cli" >nul
copy /Y "%SCRIPT_DIR%shortener.bat" "%INSTALL_DIR%\shortener.bat" >nul
copy /Y "%SCRIPT_DIR%shortener.ps1" "%INSTALL_DIR%\shortener.ps1" >nul

:: Add to PATH using Powershell for better robustness (updates Machine PATH)
powershell -Command "[Environment]::SetEnvironmentVariable('PATH', \"%INSTALL_DIR%;$([Environment]::GetEnvironmentVariable('PATH', 'Machine'))\", 'Machine')"

:: Also update CURRENT SESSION PATH so they don't have to restart
set "PATH=%INSTALL_DIR%;%PATH%"

echo  ✓ Installed successfully!
echo.
echo  IMPORTANT: Please RESTART your terminal to use the 'shortener' command.
echo.
echo  Usage:
echo    shortener help
echo    shortener start
echo    shortener webmock
echo.
