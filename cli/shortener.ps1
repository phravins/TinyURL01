# shortener.ps1 — PowerShell launcher for the URL Shortener CLI
# Works on Windows PowerShell 5.x and PowerShell Core 7+

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Escript    = Join-Path $ScriptDir "shortener_cli"

# Check escript is available
if (-not (Get-Command escript -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "  ERROR: 'escript' not found on PATH." -ForegroundColor Red
    Write-Host "  Please install Erlang from https://www.erlang.org/downloads"
    Write-Host "  and add it to your PATH environment variable."
    Write-Host ""
    exit 1
}

& escript $Escript @args
exit $LASTEXITCODE
