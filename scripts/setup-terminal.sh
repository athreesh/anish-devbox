#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# ---------- Zsh ----------
log_info "Installing zsh..."
if ! command -v zsh &>/dev/null; then
    sudo apt update
    sudo apt install -y zsh
else
    log_warn "zsh already installed: $(zsh --version)"
fi

# ---------- Starship prompt ----------
log_info "Installing starship..."
if ! command -v starship &>/dev/null; then
    mkdir -p ~/.local/bin
    curl -sS https://starship.rs/install.sh | sh -s -- -y --bin-dir ~/.local/bin
else
    log_warn "starship already installed: $(starship --version)"
fi

# ---------- eza (modern ls) ----------
log_info "Installing eza..."
if ! command -v eza &>/dev/null; then
    sudo apt install -y gpg
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg
    sudo apt update
    sudo apt install -y eza
else
    log_warn "eza already installed"
fi

# ---------- fzf ----------
log_info "Installing fzf..."
if ! command -v fzf &>/dev/null; then
    sudo apt install -y fzf
else
    log_warn "fzf already installed"
fi

# ---------- zoxide ----------
log_info "Installing zoxide..."
if ! command -v zoxide &>/dev/null; then
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
else
    log_warn "zoxide already installed"
fi

# ---------- zsh-autosuggestions ----------
ZSH_AUTOSUGGEST_DIR="/usr/share/zsh-autosuggestions"
log_info "Installing zsh-autosuggestions..."
if [ ! -d "$ZSH_AUTOSUGGEST_DIR" ]; then
    sudo apt install -y zsh-autosuggestions 2>/dev/null || {
        log_warn "apt package not available, cloning from git..."
        sudo git clone https://github.com/zsh-users/zsh-autosuggestions /usr/share/zsh-autosuggestions
    }
else
    log_warn "zsh-autosuggestions already installed"
fi

# ---------- zsh-syntax-highlighting ----------
ZSH_SYNTAX_DIR="/usr/share/zsh-syntax-highlighting"
log_info "Installing zsh-syntax-highlighting..."
if [ ! -d "$ZSH_SYNTAX_DIR" ]; then
    sudo apt install -y zsh-syntax-highlighting 2>/dev/null || {
        log_warn "apt package not available, cloning from git..."
        sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting /usr/share/zsh-syntax-highlighting
    }
else
    log_warn "zsh-syntax-highlighting already installed"
fi

# ---------- Deploy config files ----------
log_info "Installing zshrc..."
if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.bak"
    log_warn "Backed up existing .zshrc to .zshrc.bak"
fi
cp "$REPO_DIR/config/zshrc" "$HOME/.zshrc"

log_info "Installing starship config..."
mkdir -p "$HOME/.config"
cp "$REPO_DIR/config/starship.toml" "$HOME/.config/starship.toml"

# ---------- Set zsh as default shell ----------
if [ "$SHELL" != "$(which zsh)" ]; then
    log_info "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
    log_info "Default shell changed to zsh. Log out and back in for it to take effect."
else
    log_info "zsh is already the default shell"
fi

log_info "Terminal setup complete!"
log_info "Run: ${GREEN}exec zsh${NC} to start using your new shell immediately"
