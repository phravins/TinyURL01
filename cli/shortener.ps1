# shortener.ps1 — PowerShell launcher for the URL Shortener CLI
# Works on Windows PowerShell 5.x and PowerShell Core 7+

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Escript    = Join-Path $ScriptDir "shortener_cli"

# Function to find Erlang if it's not on PATH
function Find-Escript {
    # Try current PATH first
    if (Get-Command escript -ErrorAction SilentlyContinue) { return "escript" }

    # Try common installation paths
    $ErlangSearchPaths = @(
        "${env:ProgramFiles}\erl*\bin\escript.exe",
        "${env:ProgramFiles(x86)}\erl*\bin\escript.exe"
    )

    foreach ($pattern in $ErlangSearchPaths) {
        $found = Get-Item $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { return $found.FullName }
    }

    return $null
}

$EscriptPath = Find-Escript

# Check escript is available
if (-not $EscriptPath) {
    Write-Host ""
    Write-Host "  ❌ ERROR: 'escript' (Erlang) not found." -ForegroundColor Red
    Write-Host "  Please install Erlang automatically by running this in an Administrator terminal:"
    Write-Host ""
    Write-Host "  iwr https://raw.githubusercontent.com/phravins/TinyURL01/main/cli/install_remote.ps1 -useb | iex" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Alternatively, install manually from https://www.erlang.org/downloads"
    Write-Host "  and add it to your PATH environment variable."
    Write-Host ""
    exit 1
}

& "$EscriptPath" $Escript @args
exit $LASTEXITCODE
