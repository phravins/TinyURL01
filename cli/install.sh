#!/usr/bin/env bash
# install.sh — Linux/macOS installer for shortener CLI
# Usage: bash install.sh [--prefix /usr/local]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${1:-/usr/local}"
BIN_DIR="$PREFIX/bin"

# ANSI Color Codes
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

printf "\n   ${CYAN}TinyURL Local Installer${NC}\n\n"

# 0. System Diagnostics
printf "  ${BLUE}✈${NC} Performing system diagnostics...\n"

# Check for read-only filesystem
if [ ! -w /tmp ]; then
    printf "  ${RED}Error: /tmp is not writable. Your filesystem might be mounted as read-only.${NC}\n"
    exit 1
fi

# Check disk space (require at least 50MB)
FREE_SPACE=$(df -m / | awk 'NR==2 {print $4}')
if [ "$FREE_SPACE" -lt 50 ]; then
    printf "  ${RED}Error: Low disk space ($FREE_SPACE MB available).${NC}\n"
    exit 1
fi

# 1. Check Erlang
if ! command -v escript &>/dev/null; then
    printf "  ${RED}ERROR: 'escript' not found on PATH.${NC}\n\n"
    printf "  Install Erlang:\n"
    printf "    macOS  : brew install erlang\n"
    printf "    Linux  : Use your distribution's package manager (apt, dnf, etc.)\n\n"
    exit 1
fi

ERLANG_VERSION=$(escript -version 2>&1 | grep -oE '[0-9]+' | head -1)
printf "  ${GREEN}✓${NC} Erlang found (version ~$ERLANG_VERSION)\n"

# 2. Install
if [ ! -w "$BIN_DIR" ]; then
    printf "  (Requesting sudo permissions to write to $BIN_DIR)\n"
    sudo mkdir -p "$BIN_DIR"
    sudo cp "$SCRIPT_DIR/shortener_cli" "$BIN_DIR/shortener"
    sudo chmod +x "$BIN_DIR/shortener"
else
    mkdir -p "$BIN_DIR"
    cp "$SCRIPT_DIR/shortener_cli" "$BIN_DIR/shortener"
    chmod +x "$BIN_DIR/shortener"
fi

# 3. macOS: handle Gatekeeper for first run
if [[ "$(uname)" == "Darwin" ]]; then
    if [ ! -w "$BIN_DIR" ]; then
        sudo xattr -d com.apple.quarantine "$BIN_DIR/shortener" 2>/dev/null || true
    else
        xattr -d com.apple.quarantine "$BIN_DIR/shortener" 2>/dev/null || true
    fi
    printf "  ${GREEN}✓${NC} macOS Gatekeeper flag cleared\n"
fi

printf "\n  ${GREEN}✓ Installed to $BIN_DIR/shortener${NC}\n"
printf "  Usage:\n"
printf "    ${BLUE}shortener help${NC}\n"
printf "    ${BLUE}shortener start${NC} (runs production server)\n"
printf "    ${BLUE}shortener webmock${NC} (runs UI testing mock)\n\n"
