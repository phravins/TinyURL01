# Set Output Encoding to UTF8 for clean symbols
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Check for Administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "`n  ❌ ERROR: This script MUST be run as Administrator.`n" -ForegroundColor Red
    Write-Host "  To fix this: Right-click your Terminal/PowerShell and select 'Run as Administrator'.`n"
    exit 1
}

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$InstallDir = Join-Path $env:ProgramFiles "shortener-cli"
$RawBaseUrl = "https://raw.githubusercontent.com/phravins/TinyURL01/main/cli"

Write-Host "`n  TinyURL Complete Installer for Windows`n" -ForegroundColor Cyan

# 1. Check and Install Erlang
if (-not (Get-Command escript -ErrorAction SilentlyContinue)) {
    Write-Host "  Erlang not found. Downloading and installing automatically..." -ForegroundColor Yellow
    
    $ErlangInstalled = $false
    
    # Try using Winget first
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $WingetIds = @("Ericsson.Erlang", "Erlang.Erlang")
        foreach ($id in $WingetIds) {
            try {
                Write-Host "  Trying Winget to install $id..." -ForegroundColor DarkGray
                # Use --accept-source-agreements to avoid interactive prompts
                winget install $id --silent --accept-package-agreements --accept-source-agreements --no-upgrade
                if ($LASTEXITCODE -eq 0) {
                    $ErlangInstalled = $true
                    break
                } else {
                    Write-Host "  Winget failed for $id (Exit Code: $LASTEXITCODE)" -ForegroundColor DarkGray
                }
            } catch {
                Write-Host "  Winget exception for $id, trying next..." -ForegroundColor DarkGray
            }
        }
    }
    
    if (-not $ErlangInstalled) {
        # Fallback: Direct download and install
        Write-Host "  Attempting direct download (this may take a minute)..." -ForegroundColor DarkGray
        $InstallerUrl = "https://github.com/erlang/otp/releases/download/OTP-26.2.3/otp_win64_26.2.3.exe"
        $InstallerPath = Join-Path $env:TEMP "erlang_installer.exe"
        Invoke-WebRequest -Uri $InstallerUrl -OutFile $InstallerPath -UseBasicParsing
        
        Write-Host "  Running Erlang installer silently..." -ForegroundColor DarkGray
        $process = Start-Process -FilePath $InstallerPath -ArgumentList "/S" -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -ne 0) {
            Write-Host "  Failed to install Erlang automatically." -ForegroundColor Red
            exit 1
        }
        $ErlangInstalled = $true
    }
    
    if ($ErlangInstalled) {
        Write-Host "  ✓ Erlang installed successfully." -ForegroundColor Green
        # Force a reload of the machine path into the current session
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    }
} else {
    Write-Host "  ✓ Erlang is already installed." -ForegroundColor Green
}


# 2. Add Erlang to PATH just in case it was installed but not refreshed
$ErlangBinPath = "${env:ProgramFiles}\erl*\bin"
$ResolvedErlang = Resolve-Path $ErlangBinPath -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path -First 1

if ($null -ne $ResolvedErlang) {
    if ($env:Path -notlike "*$ResolvedErlang*") {
        $env:Path += ";$ResolvedErlang"
        Write-Host "  ✓ Added Erlang to current session PATH" -ForegroundColor DarkGray
    }
} else {
     # If we still can't find it, retry common locations
     $TryPaths = @("C:\Program Files\erl26.2.3\bin", "C:\Program Files\erl-26.2.3\bin")
     foreach ($tp in $TryPaths) {
         if (Test-Path $tp) {
             $ResolvedErlang = $tp
             $env:Path += ";$ResolvedErlang"
             break
         }
     }
}

# Final escript verification
if (-not (Get-Command escript -ErrorAction SilentlyContinue)) {
    Write-Host "  ⚠️ Warning: Erlang installer finished but 'escript' is still not found in standard paths." -ForegroundColor Yellow
    Write-Host "  Please manually add your Erlang bin folder to PATH."
}

# 3. Install CLI
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
}

Write-Host "  ↓ Downloading TinyURL CLI..." -ForegroundColor Blue
Invoke-WebRequest -Uri "$RawBaseUrl/shortener_cli" -OutFile "$InstallDir\shortener_cli" -UseBasicParsing
Invoke-WebRequest -Uri "$RawBaseUrl/shortener.bat" -OutFile "$InstallDir\shortener.bat" -UseBasicParsing
Invoke-WebRequest -Uri "$RawBaseUrl/shortener.ps1" -OutFile "$InstallDir\shortener.ps1" -UseBasicParsing

# Add CLI to PATH persistingly
$CurrentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
if ($CurrentPath -notlike "*$InstallDir*") {
    $NewPath = "$InstallDir;$CurrentPath"
    [Environment]::SetEnvironmentVariable("PATH", $NewPath, "Machine")
    Write-Host "  ✓ Added CLI to system PATH" -ForegroundColor Green
}

# Add CLI to CURRENT SESSION PATH so user can use it immediately
if ($env:Path -notlike "*$InstallDir*") {
    $env:Path += ";$InstallDir"
}

Write-Host "`n  ✓ Installed successfully!" -ForegroundColor Green
Write-Host "  You can now use the 'shortener' command immediately in this terminal session." -ForegroundColor Cyan
Write-Host "  (Future terminal sessions will also have it automatically)`n"
Write-Host "  Try running:" -ForegroundColor Gray
Write-Host "    shortener help   (to see examples)" -ForegroundColor Gray
Write-Host "    shortener start  (to run production server)" -ForegroundColor Gray
Write-Host "    shortener webmock (to test UI locally)`n" -ForegroundColor Gray
