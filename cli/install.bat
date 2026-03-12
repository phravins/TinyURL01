@echo off
:: install.bat — Windows installer for shortener CLI
:: Must be run as Administrator (or from a shell with write permissions to your PATH)

setlocal
set SCRIPT_DIR=%~dp0
set INSTALL_DIR=%PROGRAMFILES%\shortener-cli

echo.
echo  Installing shortener CLI to: %INSTALL_DIR%
echo.

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
copy /Y "%SCRIPT_DIR%shortener_cli" "%INSTALL_DIR%\shortener_cli" >nul
copy /Y "%SCRIPT_DIR%shortener.bat" "%INSTALL_DIR%\shortener.bat" >nul
copy /Y "%SCRIPT_DIR%shortener.ps1" "%INSTALL_DIR%\shortener.ps1" >nul

:: Add to PATH using setx (persists across sessions)
setx PATH "%INSTALL_DIR%;%PATH%" >nul 2>&1

echo  ✓ Installed successfully!
echo.
echo  Usage (restart your terminal first):
echo    shortener shorten https://example.com
echo    shortener --help
echo.
