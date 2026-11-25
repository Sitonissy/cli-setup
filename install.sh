#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

TEMP_DIR=""
cleanup() {
    if [ -n "${TEMP_DIR:-}" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

OS="$(uname -s)"
echo "OS: $OS"

# Packages
if [ "$OS" = "Darwin" ]; then
    if [ -x "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found. Install it first." >&2
        exit 1
    fi

    brew update
    brew install zsh git curl vim unzip python3 pipx bat eza fzf ripgrep lazygit zellij zoxide stow

elif [ "$OS" = "Linux" ]; then
    sudo apt update
    sudo apt install -y zsh git curl vim ca-certificates unzip python3 python3-pip pipx acl bat fzf ripgrep zoxide stow

    for pkg in eza lazygit zellij; do
        if apt-cache show "$pkg" >/dev/null 2>&1; then
            sudo apt install -y "$pkg"
        else
            echo "Skipping $pkg (not in APT repos)."
        fi
    done

    if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    fi
else
    echo "Unsupported OS: $OS" >&2
    exit 1
fi

pipx ensurepath

# Oh My Zsh + plugins
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
fi

ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM_DIR/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM_DIR/themes/powerlevel10k"
fi

if [ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting" ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"
fi

# Dracula PRO theme
read -rp "Install Dracula PRO Van Helsing theme? [y/N]: " INSTALL_THEME

if [[ "${INSTALL_THEME:-}" =~ ^[Yy]$ ]]; then
    if [ ! -f "dracula-pro.zip.enc" ]; then
        echo "dracula-pro.zip.enc not found in $SCRIPT_DIR, skipping."
    else
        TEMP_DIR="$(mktemp -d)"

        if openssl enc -d -aes-256-cbc -pbkdf2 -in dracula-pro.zip.enc -out "$TEMP_DIR/dracula-pro.zip"; then
            unzip -q "$TEMP_DIR/dracula-pro.zip" -d "$TEMP_DIR"

            VIM_THEME_DIR="$HOME/.vim/pack/themes/start/dracula_pro"
            mkdir -p "$VIM_THEME_DIR"
            cp -R "$TEMP_DIR/dracula-pro/vim/"* "$VIM_THEME_DIR/"

            if [ "$OS" = "Darwin" ] && [ -d "/Applications/iTerm.app" ]; then
                open "$TEMP_DIR/dracula-pro/iterm/Dracula Pro (Van Helsing).itermcolors"
                sleep 2
            fi
        else
            echo "Decryption failed, skipping theme."
        fi

        rm -rf "$TEMP_DIR"
        TEMP_DIR=""
    fi
fi

# Git & GitHub
read -rp "Configure Git and GitHub token? [Y/n]: " CONFIG_GIT
CONFIG_GIT="${CONFIG_GIT:-Y}"

if [[ "$CONFIG_GIT" =~ ^[Yy]$ ]]; then
    read -rp "Git Name [Sitonissy]: " GIT_NAME
    GIT_NAME="${GIT_NAME:-Sitonissy}"

    read -rp "Git Email: " GIT_EMAIL

    cat > "$HOME/.gitconfig.local" << EOF
[user]
    name = $GIT_NAME
    email = $GIT_EMAIL
EOF

    read -rsp "GitHub Personal Access Token (Enter to skip): " GITHUB_TOKEN
    echo ""

    if [ -n "$GITHUB_TOKEN" ]; then
        touch "$HOME/.zshlocal"
        grep -v "^export GITHUB_TOKEN=" "$HOME/.zshlocal" > "$HOME/.zshlocal.tmp" || true
        mv "$HOME/.zshlocal.tmp" "$HOME/.zshlocal"

        echo "export GITHUB_TOKEN=\"$GITHUB_TOKEN\"" >> "$HOME/.zshlocal"
        chmod 600 "$HOME/.zshlocal"

        if [ "$OS" = "Darwin" ]; then
            cat >> "$HOME/.gitconfig.local" << EOF
[credential]
    helper = osxkeychain
EOF
            printf "protocol=https\nhost=github.com\nusername=oauth2\npassword=%s\n\n" "$GITHUB_TOKEN" | git credential-osxkeychain store
        else
            cat >> "$HOME/.gitconfig.local" << EOF
[credential]
    helper = store
EOF
            touch "$HOME/.git-credentials"
            grep -v "@github.com$" "$HOME/.git-credentials" > "$HOME/.git-credentials.tmp" || true
            mv "$HOME/.git-credentials.tmp" "$HOME/.git-credentials"
            echo "https://oauth2:${GITHUB_TOKEN}@github.com" >> "$HOME/.git-credentials"
            chmod 600 "$HOME/.git-credentials"
        fi
    fi
fi

# Stow configs
mkdir -p "$HOME/.vim"

backup_if_exists() {
    if [ -f "$1" ] && [ ! -L "$1" ]; then
        mv "$1" "${1}.bak.$(date +%s)"
    fi
}

backup_if_exists "$HOME/.zshrc"
backup_if_exists "$HOME/.p10k.zsh"
backup_if_exists "$HOME/.zsh_aliases"
backup_if_exists "$HOME/.zshlocal.example"
backup_if_exists "$HOME/.vimrc"
backup_if_exists "$HOME/.gitconfig"

stow -v -R -t "$HOME" zsh vim git

# Default shell
ZSH_BIN="$(command -v zsh)"
if [ "${SHELL:-}" != "$ZSH_BIN" ]; then
    chsh -s "$ZSH_BIN" || echo "Run manually: chsh -s $ZSH_BIN"
fi

# macOS defaults
if [ "$OS" = "Darwin" ] && [ -f "macos-defaults.sh" ]; then
    bash macos-defaults.sh
fi

echo "Done. Restart your terminal or run 'zsh'."

