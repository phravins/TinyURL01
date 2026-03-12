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
    echo  ERROR: 'escript' not found on PATH.
    echo  Please install Erlang from https://www.erlang.org/downloads
    echo  and add it to your PATH environment variable.
    echo.
    exit /b 1
)

escript "%ESCRIPT%" %*
exit /b %ERRORLEVEL%
