# install_remote.ps1 — 1-Liner Windows fully automated installer
# Usage: iwr https://raw.githubusercontent.com/phravins/TinyURL01/main/cli/install_remote.ps1 -useb | iex
# Must be run as Administrator

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$InstallDir = Join-Path $env:ProgramFiles "shortener-cli"
$RawBaseUrl = "https://raw.githubusercontent.com/phravins/TinyURL01/main/cli"

Write-Host "`n  ✨ TinyURL Complete Installer for Windows`n" -ForegroundColor Cyan

# 1. Check and Install Erlang
if (-not (Get-Command escript -ErrorAction SilentlyContinue)) {
    Write-Host "  Erlang not found. Downloading and installing automatically..." -ForegroundColor Yellow
    
    # Try using Winget first
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "  Using Winget to install Erlang..." -ForegroundColor DarkGray
        winget install Erlang.Erlang --silent --accept-package-agreements --accept-source-agreements
    } else {
        # Fallback: Direct download and install
        Write-Host "  Winget not found. Downloading OTP installer directly (this may take a minute)..." -ForegroundColor DarkGray
        $InstallerUrl = "https://github.com/erlang/otp/releases/download/OTP-26.2.3/otp_win64_26.2.3.exe"
        $InstallerPath = Join-Path $env:TEMP "erlang_installer.exe"
        Invoke-WebRequest -Uri $InstallerUrl -OutFile $InstallerPath -UseBasicParsing
        
        Write-Host "  Running Erlang installer silently..." -ForegroundColor DarkGray
        $process = Start-Process -FilePath $InstallerPath -ArgumentList "/S" -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -ne 0) {
            Write-Host "  Failed to install Erlang automatically." -ForegroundColor Red
            exit 1
        }
    }
    
    Write-Host "  ✓ Erlang installed successfully." -ForegroundColor Green
    
    # Reload environment variables for the current PowerShell session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
    Write-Host "  ✓ Erlang is already installed." -ForegroundColor Green
}

# 2. Add Erlang to PATH just in case it was installed but not refreshed
$ErlangPath = "C:\Program Files\erl*\bin"
$ResolvedErlang = Resolve-Path $ErlangPath -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path -First 1
if ($null -ne $ResolvedErlang -and $env:Path -notlike "*$ResolvedErlang*") {
    $env:Path += ";$ResolvedErlang"
}

# 3. Install CLI
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
}

Write-Host "  ↓ Downloading TinyURL CLI..." -ForegroundColor Blue
Invoke-WebRequest -Uri "$RawBaseUrl/shortener_cli" -OutFile "$InstallDir\shortener_cli" -UseBasicParsing
Invoke-WebRequest -Uri "$RawBaseUrl/shortener.bat" -OutFile "$InstallDir\shortener.bat" -UseBasicParsing
Invoke-WebRequest -Uri "$RawBaseUrl/shortener.ps1" -OutFile "$InstallDir\shortener.ps1" -UseBasicParsing

# Add CLI to PATH
$CurrentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
if ($CurrentPath -notlike "*$InstallDir*") {
    $NewPath = "$InstallDir;$CurrentPath"
    [Environment]::SetEnvironmentVariable("PATH", $NewPath, "Machine")
    Write-Host "  ✓ Added CLI to system PATH" -ForegroundColor Green
}

Write-Host "`n  ✓ Installed successfully!" -ForegroundColor Green
Write-Host "  IMPORTANT: Please RESTART your terminal to use the 'shortener' command." -ForegroundColor Yellow
Write-Host "  After restarting, try running: shortener webmock`n" -ForegroundColor Cyan
