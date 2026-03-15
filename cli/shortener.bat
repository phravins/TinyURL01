@echo off
:: shortener.bat — Windows launcher for the URL Shortener CLI

setlocal enabledelayedexpansion
set SCRIPT_DIR=%~dp0
set ESCRIPT_CLI=%SCRIPT_DIR%shortener_cli

:: 1. Check if escript is already in PATH
where escript >nul 2>&1
if %ERRORLEVEL% equ 0 (
    set ESCRIPT_EXE=escript
    goto :RUN
)

:: 2. Try common installation paths
for /d %%D in ("%ProgramFiles%\erl*") do (
    if exist "%%D\bin\escript.exe" (
        set ESCRIPT_EXE="%%D\bin\escript.exe"
        goto :RUN
    )
)

for /d %%D in ("%ProgramFiles(x86)%\erl*") do (
    if exist "%%D\bin\escript.exe" (
        set ESCRIPT_EXE="%%D\bin\escript.exe"
        goto :RUN
    )
)

:: 3. Error out if not found
echo.
echo  ❌ ERROR: 'escript' (Erlang) not found.
echo.
echo  Please install Erlang automatically by running this in an Administrator terminal:
echo  iwr https://raw.githubusercontent.com/phravins/TinyURL01/main/cli/install_remote.ps1 -useb ^| iex
echo.
echo  Alternatively, install manually from https://www.erlang.org/downloads
echo.
exit /b 1

:RUN
%ESCRIPT_EXE% "%ESCRIPT_CLI%" %*
exit /b %ERRORLEVEL%
