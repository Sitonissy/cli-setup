#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

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
    
    # Ensure Homebrew is installed
    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found. Please install Homebrew first."
        exit 1
    fi

    brew update
    brew install zsh git curl vim unzip python3 pipx bat eza fzf ripgrep lazygit zellij zoxide stow

elif [ "$OS" = "Linux" ]; then
    echo "Linux detected. Using APT..."
    
    sudo apt update
    sudo apt install -y zsh git curl vim ca-certificates unzip python3 python3-pip pipx acl batcat eza fzf ripgrep lazygit zoxide stow
    
    # Note: If 'zellij' or 'eza' are missing from standard apt repos on older Ubuntu versions,
    # they might require downloading their binaries or installing via cargo.
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
    echo "Decrypting premium theme..."
    
    # Attempt to decrypt the archive
    if openssl enc -d -aes-256-cbc -pbkdf2 -in dracula-pro.zip.enc -out dracula-pro.zip; then
        echo "✅ Theme decrypted successfully."
        
        # Create a temporary directory for extraction
        TEMP_DIR=$(mktemp -d)
        unzip -q dracula-pro.zip -d "$TEMP_DIR"
        
        # --- 1. Install Vim Theme ---
        echo "Configuring Vim theme..."
        VIM_THEME_DIR="$HOME/.vim/pack/themes/start/dracula_pro"
        mkdir -p "$VIM_THEME_DIR"
        cp -R "$TEMP_DIR/dracula-pro/vim/"* "$VIM_THEME_DIR/"
        
        # --- 2. Install iTerm2 Theme (macOS only) ---
        if [ "$OS" = "Darwin" ]; then
            echo "Importing iTerm2 theme (Van Helsing)..."
            # Opening the .itermcolors file automatically imports it into iTerm2
            open "$TEMP_DIR/dracula-pro/iterm/Dracula Pro (Van Helsing).itermcolors"
        fi
        
        # Cleanup decrypted zip and temporary files
        rm dracula-pro.zip
        rm -rf "$TEMP_DIR"
        echo "✅ Premium theme installed successfully."
    else
        echo "❌ Incorrect password or decryption failed."
        echo "Skipping premium theme. The default terminal colors will be used."
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

    # Request GitHub Token silently (characters will not be displayed)
    read -sp "Enter your GitHub Personal Access Token (or press Enter to skip): " GITHUB_TOKEN
    echo "" # Add newline after silent prompt

    if [ -n "$GITHUB_TOKEN" ]; then
        # 1. Save to .zshlocal for environment variables (used by many CLI tools)
        echo "" >> "$HOME/.zshlocal"
        echo "# GitHub Token configured via install.sh" >> "$HOME/.zshlocal"
        echo "export GITHUB_TOKEN=\"$GITHUB_TOKEN\"" >> "$HOME/.zshlocal"

        # 2. Configure Git to use the token for HTTPS authentication
        # Add credential helper to local gitconfig
        cat >> "$HOME/.gitconfig.local" << EOF
[credential]
    helper = store
EOF

        # Write the token to the secure credentials file
        echo "https://oauth2:${GITHUB_TOKEN}@github.com" > "$HOME/.git-credentials"

        # Lock down the permissions of the credentials file so only you can read it
        chmod 600 "$HOME/.git-credentials"

        echo "✅ GitHub token securely saved to ~/.zshlocal and ~/.git-credentials"
    fi
else
    echo "Skipping Git configuration."
fi

# 4. GNU Stow (Symlinking configurations)
echo "======================================================"
echo "Applying configurations using GNU Stow..."

# Ensure we are in the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Create target directories if they don't exist to prevent Stow from symlinking entire folders
mkdir -p "$HOME/.vim"

# Stow modules into the home directory
stow -v -t "$HOME" zsh
stow -v -t "$HOME" vim
stow -v -t "$HOME" git

echo "✅ Configurations linked successfully."

# 5. macOS specific UI defaults
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
