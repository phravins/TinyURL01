#!/usr/bin/env bash
# install.sh — Linux/macOS installer for shortener CLI
# Usage: bash install.sh [--prefix /usr/local]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${1:-/usr/local}"
BIN_DIR="$PREFIX/bin"

echo ""
echo "  Installing shortener CLI to: $BIN_DIR"
echo ""

# --- Check Erlang ---
if ! command -v escript &>/dev/null; then
    echo "  ERROR: 'escript' not found on PATH."
    echo ""
    echo "  Install Erlang:"
    echo "    macOS  : brew install erlang"
    echo "    Ubuntu : sudo apt-get install erlang"
    echo "    Fedora : sudo dnf install erlang"
    echo "    Arch   : sudo pacman -S erlang"
    echo ""
    exit 1
fi

ERLANG_VERSION=$(escript -version 2>&1 | grep -oE '[0-9]+' | head -1)
echo "  ✓ Erlang found (version ~$ERLANG_VERSION)"

# --- Install ---
mkdir -p "$BIN_DIR"

cp "$SCRIPT_DIR/shortener_cli" "$BIN_DIR/shortener"
chmod +x "$BIN_DIR/shortener"

echo "  ✓ Installed to $BIN_DIR/shortener"
echo ""
echo "  Usage:"
echo "    shortener shorten https://example.com"
echo "    shortener help"
echo ""

# --- macOS: handle Gatekeeper for first run ---
if [[ "$(uname)" == "Darwin" ]]; then
    xattr -d com.apple.quarantine "$BIN_DIR/shortener" 2>/dev/null || true
    echo "  ✓ macOS Gatekeeper flag cleared"
    echo ""
fi
