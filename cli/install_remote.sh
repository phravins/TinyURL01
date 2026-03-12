#!/usr/bin/env bash
# install_remote.sh — 1-Liner Linux/macOS fully automated installer
# Usage: curl -fsSL https://raw.githubusercontent.com/phravins/TinyURL01/main/cli/install_remote.sh | bash

set -e

PREFIX="${1:-/usr/local}"
BIN_DIR="$PREFIX/bin"
RAW_URL="https://raw.githubusercontent.com/phravins/TinyURL01/main/cli/shortener_cli"

echo -e "\n   \033[1;36mTinyURL Complete Installer\033[0m\n"

# 1. Check and Install Erlang automatically
if ! command -v escript &>/dev/null; then
    echo -e "  \033[1;33mErlang not found. Installing automatically...\033[0m"
    if [[ "$(uname)" == "Darwin" ]]; then
        if ! command -v brew &>/dev/null; then
            echo -e "  \033[1;31mError: Homebrew is required on macOS for automated installation.\033[0m"
            echo -e "  Install Homebrew first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
        echo "  Running: brew install erlang"
        brew install erlang
    elif [[ "$(uname)" == "Linux" ]]; then
        if command -v apt-get &>/dev/null; then
            echo "  Running: apt-get install erlang (Requires sudo)"
            sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y erlang
        elif command -v dnf &>/dev/null; then
            echo "  Running: dnf install erlang (Requires sudo)"
            sudo dnf install -y erlang
        elif command -v yum &>/dev/null; then
            echo "  Running: yum install erlang (Requires sudo)"
            sudo yum install -y erlang
        elif command -v pacman &>/dev/null; then
            echo "  Running: pacman -S erlang (Requires sudo)"
            sudo pacman -S --noconfirm erlang
        elif command -v apk &>/dev/null; then
            echo "  Running: apk add erlang (Requires sudo)"
            sudo apk add erlang
        else
            echo -e "  \033[1;31mError: Unsupported Linux package manager. Please install Erlang manually.\033[0m"
            exit 1
        fi
    else
        echo -e "  \033[1;31mError: Unsupported OS for auto-install. Please install Erlang manually.\033[0m"
        exit 1
    fi
    echo -e "  \033[1;32m✓\033[0m Erlang installed successfully."
else
    ERLANG_VERSION=$(escript -version 2>&1 | grep -oE '[0-9]+' | head -1)
    echo -e "  \033[1;32m✓\033[0m Erlang already installed (v~$ERLANG_VERSION)"
fi

# 2. Download and Install CLI
echo -e "  \033[1;34m↓\033[0m Downloading TinyURL CLI to $BIN_DIR..."

if [ ! -w "$BIN_DIR" ]; then
    echo "  (Requesting sudo permissions to write to $BIN_DIR)"
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

echo -e "\n  \033[1;32m✓ Installed successfully!\033[0m"
echo -e "  To get started, try running:"
echo -e "    \033[1mshortener webmock\033[0m (to test UI locally)"
echo -e "    \033[1mshortener shorten https://google.com\033[0m\n"
