#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Ensure we are always working from the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "======================================================"
echo "🚀 Starting dotfiles installation..."
echo "======================================================"

# 1. Detect Operating System
OS="$(uname -s)"
echo "Detected OS: $OS"

# 2. Package Installation
echo "Installing necessary packages..."

if [ "$OS" = "Darwin" ]; then
    echo "macOS detected. Using Homebrew..."

    # Ensure Homebrew is in PATH (Apple Silicon & Intel)
    if [ -x "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    if ! command -v brew >/dev/null 2>&1; then
        echo "❌ Homebrew not found. Please install Homebrew first."
        exit 1
    fi

    brew update
    brew install zsh git curl vim unzip python3 pipx bat eza fzf ripgrep lazygit zellij zoxide stow

elif [ "$OS" = "Linux" ]; then
    echo "Linux detected. Using APT..."

    sudo apt update

    # Core packages available in standard Debian/Ubuntu repositories
    sudo apt install -y zsh git curl vim ca-certificates unzip python3 python3-pip pipx acl bat fzf ripgrep zoxide stow

    # Optional packages that may be missing on older Ubuntu/Debian versions
    for pkg in eza lazygit zellij; do
        if ! sudo apt install -y "$pkg" 2>/dev/null; then
            echo "⚠️  Package '$pkg' is not available in your APT repos. Skipping (install manually via GitHub Releases or cargo)."
        fi
    done
else
    echo "❌ Unsupported OS: $OS"
    exit 1
fi

# Ensure pipx path is set correctly
pipx ensurepath

# =====================================================================
# 3. Premium Theme Installation (Interactive)
# =====================================================================
echo "======================================================"
read -p "Install premium Dracula PRO Van Helsing theme? (Password required) [y/N]: " INSTALL_THEME

if [[ "$INSTALL_THEME" =~ ^[Yy]$ ]]; then
    if [ ! -f "dracula-pro.zip.enc" ]; then
        echo "❌ File 'dracula-pro.zip.enc' not found in $SCRIPT_DIR. Skipping."
    else
        echo "Decrypting premium theme..."
        TEMP_DIR=$(mktemp -d)

        if openssl enc -d -aes-256-cbc -pbkdf2 -in dracula-pro.zip.enc -out "$TEMP_DIR/dracula-pro.zip"; then
            echo "✅ Theme decrypted successfully."
            unzip -q "$TEMP_DIR/dracula-pro.zip" -d "$TEMP_DIR"

            # --- 1. Install Vim Theme ---
            echo "Configuring Vim theme..."
            VIM_THEME_DIR="$HOME/.vim/pack/themes/start/dracula_pro"
            mkdir -p "$VIM_THEME_DIR"
            cp -R "$TEMP_DIR/dracula-pro/vim/"* "$VIM_THEME_DIR/"

            # --- 2. Install iTerm2 Theme (macOS only) ---
            if [ "$OS" = "Darwin" ]; then
                echo "Importing iTerm2 theme (Van Helsing)..."
                open "$TEMP_DIR/dracula-pro/iterm/Dracula Pro (Van Helsing).itermcolors"
                # Give iTerm2 time to read the file before deleting TEMP_DIR
                sleep 2
            fi

            echo "✅ Premium theme installed successfully."
        else
            echo "❌ Incorrect password or decryption failed."
            echo "Skipping premium theme. The default terminal colors will be used."
        fi

        # Always clean up temporary files
        rm -rf "$TEMP_DIR"
    fi
else
    echo "Skipping premium theme installation."
fi

# =====================================================================
# 3.5 Git & GitHub Configuration (Interactive)
# =====================================================================
echo "======================================================"
read -p "Do you want to configure Git and GitHub token now? [Y/n]: " CONFIG_GIT
CONFIG_GIT=${CONFIG_GIT:-Y}

if [[ "$CONFIG_GIT" =~ ^[Yy]$ ]]; then
    echo "Configuring Git..."

    read -p "Enter your Git Name [Sitonissy]: " GIT_NAME
    GIT_NAME=${GIT_NAME:-Sitonissy}

    read -p "Enter your Git Email: " GIT_EMAIL

    # Create the local gitconfig file
    cat > "$HOME/.gitconfig.local" << EOF
[user]
    name = $GIT_NAME
    email = $GIT_EMAIL
EOF
    echo "✅ Git basic credentials saved to ~/.gitconfig.local"

    # Request GitHub Token silently
    read -sp "Enter your GitHub Personal Access Token (or press Enter to skip): " GITHUB_TOKEN
    echo ""

    if [ -n "$GITHUB_TOKEN" ]; then
        # 1. Save to .zshlocal without duplicating existing GITHUB_TOKEN entries
        touch "$HOME/.zshlocal"
        grep -v "^export GITHUB_TOKEN=" "$HOME/.zshlocal" | grep -v "^# GitHub Token configured via install.sh" > "$HOME/.zshlocal.tmp" || true
        mv "$HOME/.zshlocal.tmp" "$HOME/.zshlocal"

        {
            echo ""
            echo "# GitHub Token configured via install.sh"
            echo "export GITHUB_TOKEN=\"$GITHUB_TOKEN\""
        } >> "$HOME/.zshlocal"
        chmod 600 "$HOME/.zshlocal"

        # 2. Configure Git to use the token for HTTPS authentication
        cat >> "$HOME/.gitconfig.local" << EOF
[credential]
    helper = store
EOF

        echo "https://oauth2:${GITHUB_TOKEN}@github.com" > "$HOME/.git-credentials"
        chmod 600 "$HOME/.git-credentials"

        echo "✅ GitHub token securely saved to ~/.zshlocal and ~/.git-credentials"
    fi
else
    echo "Skipping Git configuration."
fi

# =====================================================================
# 4. GNU Stow (Symlinking configurations)
# =====================================================================
echo "======================================================"
echo "Applying configurations using GNU Stow..."

# Create target directories if they don't exist to prevent Stow from symlinking entire folders
mkdir -p "$HOME/.vim"

# Backup existing real files (not symlinks) to prevent Stow conflicts
backup_if_exists() {
    if [ -f "$1" ] && [ ! -L "$1" ]; then
        local backup="${1}.bak.$(date +%s)"
        echo "📦 Backing up existing $1 -> $backup"
        mv "$1" "$backup"
    fi
}

backup_if_exists "$HOME/.zshrc"
backup_if_exists "$HOME/.vimrc"
backup_if_exists "$HOME/.gitconfig"

# Restow (-R) modules into the home directory so re-runs work cleanly
stow -v -R -t "$HOME" zsh vim git

echo "✅ Configurations linked successfully."

# =====================================================================
# 5. macOS specific UI defaults
# =====================================================================
if [ "$OS" = "Darwin" ]; then
    if [ -f "macos-defaults.sh" ]; then
        echo "======================================================"
        echo "Applying macOS UI settings..."
        bash macos-defaults.sh
    fi
fi

echo "======================================================"
echo "🎉 Installation complete!"
echo "Please restart your terminal or type 'zsh' to apply all changes."
echo "======================================================"

