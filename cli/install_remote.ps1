# install_remote.ps1 — 1-Liner Windows installer for URL Shortener CLI
# Usage: iwr https://raw.githubusercontent.com/phravins/TinyURL01/main/cli/install_remote.ps1 -useb | iex
# Must be run as Administrator

$ErrorActionPreference = "Stop"

$InstallDir = Join-Path $env:ProgramFiles "shortener-cli"
$RawBaseUrl = "https://raw.githubusercontent.com/phravins/TinyURL01/main/cli"

Write-Host "`n  ✨ Installing URL Shortener CLI to $InstallDir...`n" -ForegroundColor Cyan

# Check Erlang
if (-not (Get-Command escript -ErrorAction SilentlyContinue)) {
    Write-Host "  ERROR: 'escript' not found on PATH." -ForegroundColor Red
    Write-Host "`n  Please install Erlang from https://www.erlang.org/downloads first.`n"
    exit 1
}
Write-Host "  ✓ Erlang found" -ForegroundColor Green

# Create dir
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
}

# Download files
Write-Host "  ↓ Downloading files from GitHub..." -ForegroundColor Blue
Invoke-WebRequest -Uri "$RawBaseUrl/shortener_cli" -OutFile "$InstallDir\shortener_cli" -UseBasicParsing
Invoke-WebRequest -Uri "$RawBaseUrl/shortener.bat" -OutFile "$InstallDir\shortener.bat" -UseBasicParsing
Invoke-WebRequest -Uri "$RawBaseUrl/shortener.ps1" -OutFile "$InstallDir\shortener.ps1" -UseBasicParsing

# Add to PATH
$CurrentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
if ($CurrentPath -notlike "*$InstallDir*") {
    $NewPath = "$InstallDir;$CurrentPath"
    [Environment]::SetEnvironmentVariable("PATH", $NewPath, "Machine")
    Write-Host "  ✓ Added $InstallDir to system PATH" -ForegroundColor Green
}

Write-Host "`n  ✓ Installed successfully!" -ForegroundColor Green
Write-Host "  Please RESTART your terminal to use the 'shortener' command.`n"
