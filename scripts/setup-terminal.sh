#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

log_info "Setting up terminal optimizations..."

# Install modern CLI tools
log_info "Installing modern CLI tools..."
sudo apt-get install -y -qq \
    fzf \
    bat \
    fd-find \
    ripgrep \
    tree \
    ncdu

# Create symlinks for fd (Ubuntu names it fdfind)
if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
    mkdir -p ~/.local/bin
    ln -sf $(which fdfind) ~/.local/bin/fd
    log_info "Created fd symlink"
fi

# Create symlinks for bat (Ubuntu names it batcat)
if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
    mkdir -p ~/.local/bin
    ln -sf $(which batcat) ~/.local/bin/bat
    log_info "Created bat symlink"
fi

# Detect shell
SHELL_NAME=$(basename "$SHELL")
SHELL_RC="$HOME/.bashrc"
if [ "$SHELL_NAME" = "zsh" ]; then
    SHELL_RC="$HOME/.zshrc"
fi

log_info "Detected shell: $SHELL_NAME (config: $SHELL_RC)"

# Backup existing config
if [ -f "$SHELL_RC" ]; then
    cp "$SHELL_RC" "${SHELL_RC}.backup.$(date +%Y%m%d%H%M%S)"
    log_info "Backed up existing $SHELL_RC"
fi

# Add terminal optimizations to shell config
log_info "Adding terminal optimizations to $SHELL_RC..."

# Check if our config block already exists
if ! grep -q "# anish-devbox terminal optimizations" "$SHELL_RC" 2>/dev/null; then
    cat >> "$SHELL_RC" << 'SHELLCONFIG'

# anish-devbox terminal optimizations
# ====================================

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# Better history
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend 2>/dev/null || true

# Useful aliases
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git aliases
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline -20'
alias gp='git pull'
alias gc='git commit'
alias ga='git add'
alias gco='git checkout'
alias gb='git branch'

# Kubernetes aliases (if kubectl available)
if command -v kubectl &> /dev/null; then
    alias k='kubectl'
    alias kgp='kubectl get pods'
    alias kgn='kubectl get nodes'
    alias kgs='kubectl get svc'
    alias kga='kubectl get all'
    alias kdp='kubectl describe pod'
    alias kl='kubectl logs'
    alias klf='kubectl logs -f'
fi

# Docker aliases
if command -v docker &> /dev/null; then
    alias d='docker'
    alias dps='docker ps'
    alias dpsa='docker ps -a'
    alias di='docker images'
fi

# GPU monitoring
if command -v nvidia-smi &> /dev/null; then
    alias gpus='watch -n 1 nvidia-smi'
    alias gpu='nvidia-smi'
fi

# Modern tool aliases (if installed)
command -v bat &> /dev/null && alias cat='bat --paging=never'
command -v batcat &> /dev/null && alias cat='batcat --paging=never'
command -v fd &> /dev/null && alias find='fd'
command -v fdfind &> /dev/null && alias find='fdfind'

# FZF configuration
if command -v fzf &> /dev/null; then
    # Use fd for fzf if available
    if command -v fd &> /dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    elif command -v fdfind &> /dev/null; then
        export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
    fi
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

    # Source fzf keybindings if available
    [ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && source /usr/share/doc/fzf/examples/key-bindings.bash
    [ -f /usr/share/doc/fzf/examples/completion.bash ] && source /usr/share/doc/fzf/examples/completion.bash
fi

# Custom prompt with git branch
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

# Colorful prompt with git branch
if [ -n "$BASH_VERSION" ]; then
    export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[33m\]$(parse_git_branch)\[\033[00m\]\$ '
fi

# Enable programmable completion
if ! shopt -oq posix 2>/dev/null; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Kubectl completion
if command -v kubectl &> /dev/null; then
    source <(kubectl completion bash 2>/dev/null) || true
    complete -F __start_kubectl k 2>/dev/null || true
fi

# GitHub CLI completion
if command -v gh &> /dev/null; then
    eval "$(gh completion -s bash 2>/dev/null)" || true
fi

# Docker completion
if command -v docker &> /dev/null && [ -f /usr/share/bash-completion/completions/docker ]; then
    . /usr/share/bash-completion/completions/docker
fi

# Useful functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Quick search in files
search() {
    if command -v rg &> /dev/null; then
        rg "$@"
    else
        grep -r "$@"
    fi
}

# End anish-devbox terminal optimizations
SHELLCONFIG

    log_info "Terminal optimizations added to $SHELL_RC"
else
    log_warn "Terminal optimizations already present in $SHELL_RC"
fi

# Configure Git defaults
log_info "Configuring Git defaults..."
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.editor vim
git config --global color.ui auto

# Set up git aliases
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

log_info "Git configured with default settings"

log_info ""
log_info "Terminal setup complete!"
log_info ""
log_info "To apply changes, either:"
log_info "  1. Run: ${GREEN}source $SHELL_RC${NC}"
log_info "  2. Or open a new terminal"
log_info ""
log_info "Git is configured. To set your identity, run:"
log_info "  ${GREEN}git config --global user.name \"Your Name\"${NC}"
log_info "  ${GREEN}git config --global user.email \"your@email.com\"${NC}"
log_info ""
log_info "To authenticate with GitHub:"
log_info "  ${GREEN}gh auth login${NC}"
