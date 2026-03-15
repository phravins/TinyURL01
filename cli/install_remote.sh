#!/usr/bin/env bash
# install_remote.sh — 1-Liner Linux/macOS fully automated installer
# Usage: curl -fsSL https://raw.githubusercontent.com/phravins/TinyURL01/main/cli/install_remote.sh | bash

set -e

PREFIX="${1:-/usr/local}"
BIN_DIR="$PREFIX/bin"
RAW_URL="https://raw.githubusercontent.com/phravins/TinyURL01/main/cli/shortener_cli"

# ANSI Color Codes
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

printf "\n   ${CYAN}TinyURL Complete Installer${NC}\n\n"

# 0. System Diagnostics
printf "  ${BLUE}✈${NC} Performing system diagnostics...\n"

# Check for read-only filesystem
if [ ! -w /tmp ]; then
    printf "  ${RED}Error: /tmp is not writable. Your filesystem might be mounted as read-only.${NC}\n"
    printf "  Check with: mount | grep \" / \"\n"
    exit 1
fi

# Check disk space (require at least 50MB)
FREE_SPACE=$(df -m / | awk 'NR==2 {print $4}')
if [ "$FREE_SPACE" -lt 50 ]; then
    printf "  ${RED}Error: Low disk space ($FREE_SPACE MB available).${NC}\n"
    printf "  Please free up some space and try again.\n"
    exit 1
fi

# 1. Check and Install Erlang automatically
check_erlang() {
    if command -v escript &>/dev/null; then
        ERLANG_VERSION=$(escript -version 2>&1 | grep -oE '[0-9]+' | head -1)
        return 0
    fi
    return 1
}

if ! check_erlang; then
    printf "  ${YELLOW}Erlang not found. Installing automatically...${NC}\n"
    OS_TYPE="$(uname)"
    
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        if ! command -v brew &>/dev/null; then
            printf "  ${RED}Error: Homebrew is required on macOS for automated installation.${NC}\n"
            printf "  Install Homebrew first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"\n"
            exit 1
        fi
        printf "  Running: brew install erlang\n"
        brew install erlang
    elif [[ "$OS_TYPE" == "Linux" ]]; then
        if command -v apt-get &>/dev/null; then
            printf "  Running: apt-get install erlang (Requires sudo)\n"
            sudo apt-get update || { printf "  ${RED}Error: apt-get update failed.${NC}\n"; exit 1; }
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y erlang
        elif command -v dnf &>/dev/null; then
            printf "  Running: dnf install erlang (Requires sudo)\n"
            sudo dnf install -y erlang
        elif command -v yum &>/dev/null; then
            printf "  Running: yum install erlang (Requires sudo)\n"
            sudo yum install -y erlang
        elif command -v pacman &>/dev/null; then
            printf "  Running: pacman -S erlang (Requires sudo)\n"
            sudo pacman -S --noconfirm erlang
        elif command -v apk &>/dev/null; then
            printf "  Running: apk add erlang (Requires sudo)\n"
            sudo apk add erlang
        else
            printf "  ${RED}Error: Unsupported Linux package manager. Please install Erlang manually.${NC}\n"
            exit 1
        fi
    elif [[ "$OS_TYPE" == MINGW* || "$OS_TYPE" == CYGWIN* || "$OS_TYPE" == MSYS* ]]; then
        printf "  ${CYAN}Windows environment detected (Bash). Attempting to install Erlang via PowerShell/Winget...${NC}\n"
        # Check for winget via powershell
        if powershell.exe -Command "Get-Command winget" &>/dev/null; then
            printf "  Running: winget install Erlang.Erlang\n"
            powershell.exe -Command "winget install Erlang.Erlang --silent --accept-package-agreements --accept-source-agreements"
        else
            printf "  ${YELLOW}winget not found. Falling back to direct download...${NC}\n"
            powershell.exe -Command "
                \$Success = \$false;
                for (\$i = 1; \$i -le 3; \$i++) {
                    try {
                        Write-Host '  Attempting download (Try ' \$i ')...';
                        Invoke-WebRequest -Uri 'https://github.com/erlang/otp/releases/download/OTP-28.4.1/otp_win64_28.4.1.exe' -OutFile '\$env:TEMP\erlang_installer.exe' -TimeoutSec 60;
                        \$Success = \$true;
                        break;
                    } catch {
                        Write-Host \"  Download failed: \$(\$_.Exception.Message)\";
                        Start-Sleep -Seconds 5;
                    }
                }
                if (\$Success) {
                    Write-Host '  Download successful. Starting installer...';
                    Start-Process -FilePath '\$env:TEMP\erlang_installer.exe' -ArgumentList '/S' -Wait;
                } else {
                    Write-Host '  Failed to download Erlang installer after multiple attempts.';
                    exit 1;
                }
            "
        fi
        
        ERLANG_BIN=$(powershell.exe -Command "Resolve-Path '${env:ProgramFiles}\erl*\bin' | Select-Object -ExpandProperty Path -First 1" | tr -d '\r')
        if [ -n "$ERLANG_BIN" ]; then
            export PATH="$PATH:$(cygpath "$ERLANG_BIN")"
        fi
    else
        printf "  ${RED}Error: Unsupported OS ($OS_TYPE) for auto-install. Please install Erlang manually.${NC}\n"
        exit 1
    fi

    if check_erlang; then
        printf "  ${GREEN}✓${NC} Erlang installed successfully (v~$ERLANG_VERSION).\n"
    else
        printf "  ${RED}Error: Erlang was installed but 'escript' is still not found in PATH.${NC}\n"
        printf "  Please restart your terminal or add Erlang to PATH manually.\n"
        exit 1
    fi
else
    printf "  ${GREEN}✓${NC} Erlang already installed (v~$ERLANG_VERSION)\n"
fi

# 2. Download and Install CLI
printf "  ${BLUE}↓${NC} Downloading TinyURL CLI to $BIN_DIR...\n"

if [ ! -w "$BIN_DIR" ]; then
    printf "  (Requesting sudo permissions to write to $BIN_DIR)\n"
    sudo mkdir -p "$BIN_DIR"
    sudo curl -fsSL "$RAW_URL" -o "$BIN_DIR/shortener"
    sudo chmod +x "$BIN_DIR/shortener"
else
    mkdir -p "$BIN_DIR"
    curl -fsSL "$RAW_URL" -o "$BIN_DIR/shortener"
    chmod +x "$BIN_DIR/shortener"
fi

# macOS Gatekeeper
if [[ "$(uname)" == "Darwin" ]]; then
    if [ ! -w "$BIN_DIR" ]; then
        sudo xattr -d com.apple.quarantine "$BIN_DIR/shortener" 2>/dev/null || true
    else
        xattr -d com.apple.quarantine "$BIN_DIR/shortener" 2>/dev/null || true
    fi
fi

printf "\n  ${GREEN}✓ Installed successfully!${NC}\n"
printf "  To get started, try running:\n"
printf "    ${BLUE}shortener help${NC} (to see all commands)\n"
printf "    ${BLUE}shortener start${NC} (to start the production server)\n"
printf "    ${BLUE}shortener webmock${NC} (to test UI locally)\n\n"
