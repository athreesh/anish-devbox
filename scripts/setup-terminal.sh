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
A3SH_DOTFILES_REPO="${A3SH_DOTFILES_REPO:-athreesh/a3sh-dotfiles}"
A3SH_DOTFILES_DIR="${A3SH_DOTFILES_DIR:-$HOME/repos/a3sh-dotfiles}"
A3SH_SKILLS_REPO="${A3SH_SKILLS_REPO:-athreesh/a3sh-skills}"
A3SH_SKILLS_DIR="${A3SH_SKILLS_DIR:-$HOME/repos/a3sh-skills}"

install_a3sh_dotfiles() {
    local repo="$A3SH_DOTFILES_REPO"
    local target_dir="$A3SH_DOTFILES_DIR"

    log_info "Installing private dotfiles from $repo..."

    if [ -d "$target_dir/.git" ]; then
        git -C "$target_dir" pull --ff-only
    elif [ -e "$target_dir" ]; then
        log_error "$target_dir already exists but is not a git checkout"
        return 1
    else
        mkdir -p "$(dirname "$target_dir")"
        if command -v gh &>/dev/null; then
            gh repo clone "$repo" "$target_dir"
        else
            git clone "https://github.com/$repo.git" "$target_dir"
        fi
    fi

    bash "$target_dir/install.sh"
}

install_a3sh_skills() {
    local repo="$A3SH_SKILLS_REPO"
    local target_dir="$A3SH_SKILLS_DIR"

    log_info "Installing private skills from $repo..."

    if [ -d "$target_dir/.git" ]; then
        git -C "$target_dir" pull --ff-only
    elif [ -e "$target_dir" ]; then
        log_error "$target_dir already exists but is not a git checkout"
        return 1
    else
        mkdir -p "$(dirname "$target_dir")"
        if command -v gh &>/dev/null; then
            gh repo clone "$repo" "$target_dir"
        else
            git clone "https://github.com/$repo.git" "$target_dir"
        fi
    fi

    bash "$target_dir/install.sh"
}

install_claude_skills_from_dir() {
    local source_dir="$1"
    local skill_dir
    local skill_name
    local target_dir

    if [ ! -d "$source_dir" ]; then
        log_warn "Claude skills source not found: $source_dir"
        return 0
    fi

    mkdir -p "$HOME/.claude/skills"

    while IFS= read -r skill_dir; do
        skill_name="$(basename "$skill_dir")"
        target_dir="$HOME/.claude/skills/$skill_name"

        rm -rf "$target_dir"
        cp -R "$skill_dir" "$target_dir"
        log_info "Installed Claude skill: $skill_name"
    done < <(find "$source_dir" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -exec test -f '{}/SKILL.md' ';' -print)
}

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

log_info "Installing tmux config..."
if [ -f "$HOME/.tmux.conf" ]; then
    cp "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak"
    log_warn "Backed up existing .tmux.conf to .tmux.conf.bak"
fi
cp "$REPO_DIR/config/tmux.conf" "$HOME/.tmux.conf"

log_info "Installing Claude config..."
mkdir -p "$HOME/.claude"
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
    cp "$HOME/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md.bak"
    log_warn "Backed up existing Claude user instructions to ~/.claude/CLAUDE.md.bak"
fi
cp "$REPO_DIR/config/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

if [ "${A3SH_DOTFILES:-0}" = "1" ]; then
    install_a3sh_dotfiles
fi

if [ "${A3SH_SKILLS:-0}" = "1" ]; then
    install_a3sh_skills
fi

if [ -n "${CLAUDE_SKILLS_SOURCE:-}" ]; then
    IFS=':' read -r -a CLAUDE_SKILLS_DIRS <<< "$CLAUDE_SKILLS_SOURCE"
    for skills_dir in "${CLAUDE_SKILLS_DIRS[@]}"; do
        install_claude_skills_from_dir "$skills_dir"
    done
fi

if [ "${CLAUDE_SYNC_CODEX_SKILLS:-0}" = "1" ]; then
    install_claude_skills_from_dir "$HOME/.codex/skills"
    install_claude_skills_from_dir "$HOME/.agents/skills"
fi

# ---------- Set zsh as default shell ----------
if [ "$SHELL" != "$(which zsh)" ]; then
    log_info "Setting zsh as default shell..."
    sudo chsh -s "$(which zsh)" "$(whoami)" 2>/dev/null || {
        log_warn "Could not change default shell automatically."
        log_warn "Run manually: sudo chsh -s $(which zsh) $(whoami)"
    }
    log_info "Default shell changed to zsh. Log out and back in for it to take effect."
else
    log_info "zsh is already the default shell"
fi

log_info "Terminal setup complete!"
log_info "Run: ${GREEN}exec zsh${NC} to start using your new shell immediately"
