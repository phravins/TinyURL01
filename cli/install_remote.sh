#!/usr/bin/env bash
# install_remote.sh — 1-Liner Linux/macOS installer for URL Shortener CLI
# Usage: curl -fsSL https://raw.githubusercontent.com/phravins/TinyURL01/main/cli/install_remote.sh | bash

set -e

PREFIX="${1:-/usr/local}"
BIN_DIR="$PREFIX/bin"
RAW_URL="https://raw.githubusercontent.com/phravins/TinyURL01/main/cli/shortener_cli"

echo -e "\n  ✨ \033[1;36mInstalling URL Shortener CLI\033[0m to $BIN_DIR...\n"

# Check Erlang
if ! command -v escript &>/dev/null; then
    echo -e "  \033[1;31mERROR:\033[0m 'escript' not found on PATH."
    echo ""
    echo "  Please install Erlang first:"
    echo "    macOS  : brew install erlang"
    echo "    Ubuntu : sudo apt-get install erlang"
    echo "    Fedora : sudo dnf install erlang"
    echo ""
    exit 1
fi

ERLANG_VERSION=$(escript -version 2>&1 | grep -oE '[0-9]+' | head -1)
echo -e "  \033[1;32m✓\033[0m Erlang found (v~$ERLANG_VERSION)"

# Download and Install
mkdir -p "$BIN_DIR"
echo -e "  \033[1;34m↓\033[0m Downloading CLI from GitHub..."
curl -fsSL "$RAW_URL" -o "$BIN_DIR/shortener"
chmod +x "$BIN_DIR/shortener"

# macOS Gatekeeper
if [[ "$(uname)" == "Darwin" ]]; then
    xattr -d com.apple.quarantine "$BIN_DIR/shortener" 2>/dev/null || true
fi

echo -e "\n  \033[1;32m✓ Installed successfully!\033[0m"
echo -e "  Run \033[1mshortener help\033[0m to get started.\n"
