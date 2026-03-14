@echo off
:: shortener.bat — Windows launcher for the URL Shortener CLI
:: Requires Erlang to be installed and 'escript' on PATH

setlocal
set SCRIPT_DIR=%~dp0
set ESCRIPT=%SCRIPT_DIR%shortener_cli

:: Check Erlang/escript is available
where escript >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  ❌ ERROR: 'escript' (Erlang) not found on PATH.
    echo.
    echo  Please install Erlang automatically by running this in an Administrator terminal:
    echo  iwr https://raw.githubusercontent.com/phravins/TinyURL01/main/cli/install_remote.ps1 -useb ^| iex
    echo.
    echo  Alternatively, install manually from https://www.erlang.org/downloads
    echo.
    exit /b 1
)

escript "%ESCRIPT%" %*
exit /b %ERRORLEVEL%
