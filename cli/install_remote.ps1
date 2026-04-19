# Set Output Encoding to UTF8 for clean symbols
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = "Stop"

# Check for Administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "`n   ERROR: This script MUST be run as Administrator.`n" -ForegroundColor Red
    Write-Host "  To fix this: Right-click your Terminal/PowerShell and select 'Run as Administrator'.`n"
    exit 1
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$InstallDir = Join-Path $env:ProgramFiles "shortener-cli"
$RawBaseUrl = "https://raw.githubusercontent.com/phravins/TinyURL01/main/cli"

function Show-Header {
    Clear-Host
    Write-Host "`n"
    Write-Host "   _______          __  __________ " -ForegroundColor Cyan
    Write-Host "  /_  __(_)___  __ / / / / __ \/ / " -ForegroundColor Cyan
    Write-Host "   / / / / __ \/ // / / / /_/ / /  " -ForegroundColor Cyan
    Write-Host "  / / / / / / / // /_/ / _, _/ /___" -ForegroundColor Cyan
    Write-Host " /_/ /_/_/ /_/\__, \____/_/ |_/_____/" -ForegroundColor Cyan
    Write-Host "             /____/                " -ForegroundColor Cyan
    Write-Host "                                   "
    Write-Host "   TinyURL Windows Installer       " -ForegroundColor Yellow
    Write-Host "`n"
}

function Show-RocketProgress {
    param(
        [int]$Percent,
        [string]$Task
    )
    $BarWidth = 40
    $Pos = [math]::Floor(($Percent / 100) * $BarWidth)
    if ($Pos -lt 1) { $Pos = 1 }
    if ($Pos -gt $BarWidth) { $Pos = $BarWidth }
    
    $Trail = "=" * ($Pos - 1)
    $Space = " " * ($BarWidth - $Pos)
    $Rocket = if ($Percent -ge 100) { "🌟" } else { "🚀" }
    
    $Line = "`r  [$Trail$Rocket$Space] $Percent%  - $Task"
    Write-Host -NoNewline $Line.PadRight(100, ' ')
}

function Invoke-SimulatedRocket {
    param([int]$Start, [int]$End, [string]$Text, [int]$SpeedMs = 20)
    for ($i = $Start; $i -le $End; $i++) {
        Show-RocketProgress -Percent $i -Task $Text
        Start-Sleep -Milliseconds $SpeedMs
    }
}

Show-Header
Invoke-SimulatedRocket 0 5 "Initializing Installer..."

# 1. Check and Install Erlang
if (-not (Get-Command escript -ErrorAction SilentlyContinue)) {
    Invoke-SimulatedRocket 5 15 "Erlang not found. Preparing download..."
    
    $ErlangInstalled = $false
    
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $WingetIds = @("Ericsson.Erlang", "Erlang.Erlang")
        foreach ($id in $WingetIds) {
            try {
                Invoke-SimulatedRocket 15 25 "Trying Winget: $id..."
                winget install $id --silent --accept-package-agreements --accept-source-agreements --no-upgrade | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    $ErlangInstalled = $true
                    Invoke-SimulatedRocket 25 50 "Erlang installed via Winget."
                    break
                }
            } catch {
                # Ignore
            }
        }
    }
    
    if (-not $ErlangInstalled) {
        Invoke-SimulatedRocket 15 20 "Attempting direct download of Erlang..."
        $InstallerUrl = "https://github.com/erlang/otp/releases/download/OTP-28.4.1/otp_win64_28.4.1.exe"
        $InstallerPath = Join-Path $env:TEMP "erlang_installer.exe"
        
        $Retries = 3
        $Success = $false
        for ($i = 1; $i -le $Retries; $i++) {
            try {
                Invoke-SimulatedRocket 20 30 "Downloading OTP 28.4.1 (Retry $i)..."
                Invoke-WebRequest -Uri $InstallerUrl -OutFile $InstallerPath -UseBasicParsing -TimeoutSec 120
                $Success = $true
                break
            } catch {
                if ($_.Exception.Message -like "*could not be resolved*") {
                    ipconfig /flushdns | Out-Null
                    Start-Sleep -Seconds 2
                }
                if ($i -lt $Retries) { Start-Sleep -Seconds 5 }
            }
        }

        if (-not $Success) {
            Write-Host "`n`n  ❌ FATAL ERROR: Could not download Erlang installer." -ForegroundColor Red
            exit 1
        }
        
        Invoke-SimulatedRocket 30 45 "Running Erlang installer silently..."
        $process = Start-Process -FilePath $InstallerPath -ArgumentList "/S" -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -ne 0) {
            Write-Host "`n`n  ❌ Failed to install Erlang automatically." -ForegroundColor Red
            exit 1
        }
        $ErlangInstalled = $true
        Invoke-SimulatedRocket 45 50 "Erlang installed successfully."
    }
    
    if ($ErlangInstalled) {
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    }
} else {
    Invoke-SimulatedRocket 5 50 "Erlang is already installed."
}

# 2. Add Erlang to PATH just in case it was installed but not refreshed
Invoke-SimulatedRocket 50 60 "Resolving Erlang PATH..."
$ErlangBinPath = "${env:ProgramFiles}\erl*\bin"
$ResolvedErlang = Resolve-Path $ErlangBinPath -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path -First 1

if ($null -ne $ResolvedErlang) {
    if ($env:Path -notlike "*$ResolvedErlang*") {
        $env:Path += ";$ResolvedErlang"
    }
} else {
     $TryPaths = @("C:\Program Files\erl26.2.3\bin", "C:\Program Files\erl-26.2.3\bin")
     foreach ($tp in $TryPaths) {
         if (Test-Path $tp) {
             $ResolvedErlang = $tp
             $env:Path += ";$ResolvedErlang"
             break
         }
     }
}

# 3. Install CLI
Invoke-SimulatedRocket 60 70 "Creating Installation Directory..."
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
}

Invoke-SimulatedRocket 70 85 "Downloading TinyURL CLI files..."
Invoke-WebRequest -Uri "$RawBaseUrl/shortener_cli" -OutFile "$InstallDir\shortener_cli" -UseBasicParsing
Invoke-WebRequest -Uri "$RawBaseUrl/shortener.bat" -OutFile "$InstallDir\shortener.bat" -UseBasicParsing
Invoke-WebRequest -Uri "$RawBaseUrl/shortener.ps1" -OutFile "$InstallDir\shortener.ps1" -UseBasicParsing

Invoke-SimulatedRocket 85 95 "Configuring Environment Variables..."
$CurrentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
if ($CurrentPath -notlike "*$InstallDir*") {
    $NewPath = "$InstallDir;$CurrentPath"
    [Environment]::SetEnvironmentVariable("PATH", $NewPath, "Machine")
}

if ($env:Path -notlike "*$InstallDir*") {
    $env:Path += ";$InstallDir"
}

Invoke-SimulatedRocket 95 100 "Finishing Installation..."
Write-Host "`n`n  🎉 Installed successfully!" -ForegroundColor Green
Write-Host "  You can now use the 'shortener' command immediately in this terminal session." -ForegroundColor Cyan
Write-Host "  (Future terminal sessions will also have it automatically)`n"
Write-Host "  Try running:" -ForegroundColor Gray
Write-Host "    shortener help   (to see examples)" -ForegroundColor Gray
Write-Host "    shortener start  (to run production server)" -ForegroundColor Gray
Write-Host "    shortener webmock (to test UI locally)`n" -ForegroundColor Gray
