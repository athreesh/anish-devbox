#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

CLAUDE_REMOTE_CONTROL_MIN_VERSION="2.1.51"
APT_INSTALL_FLAGS=(-y -qq --allow-change-held-packages)

version_at_least() {
    local current="$1"
    local minimum="$2"

    [ "$current" = "$minimum" ] && return 0
    [ "$(printf '%s\n%s\n' "$minimum" "$current" | sort -V | head -n1)" = "$minimum" ]
}

claude_supports_remote_control() {
    local current_version

    command -v claude &> /dev/null || return 1
    current_version="$(claude --version 2>/dev/null | grep -Eo '[0-9]+(\.[0-9]+)+' | head -n1 || true)"
    [ -n "$current_version" ] && version_at_least "$current_version" "$CLAUDE_REMOTE_CONTROL_MIN_VERSION"
}

# Check if running on Ubuntu
if [ ! -f /etc/os-release ] || ! grep -q "Ubuntu" /etc/os-release; then
    log_error "This script is designed for Ubuntu. Detected OS:"
    cat /etc/os-release 2>/dev/null || echo "Unknown"
    exit 1
fi

# Parse arguments
SKIP_UPGRADE=false
for arg in "$@"; do
    case $arg in
        --fast|--skip-upgrade)
            SKIP_UPGRADE=true
            ;;
    esac
done

log_info "Starting anish-devbox setup for GPU VM..."
START_TIME=$(date +%s)

# Ensure all scripts are executable (git may not preserve +x on some systems)
chmod +x scripts/*.sh 2>/dev/null || true

# ============================================================================
# PHASE 0: Install repository prerequisites
# ============================================================================
log_step "Phase 0: Installing repository prerequisites..."

# Some GPU VM images preconfigure Docker with add-apt-repository, which
# duplicates the canonical docker.list entry this script manages below.
sudo rm -f /etc/apt/sources.list.d/archive_uri-https_download_docker_com_linux_ubuntu*.list
sudo apt-get update -qq || log_warn "Initial apt update had errors; continuing so repository keys can be repaired"
sudo apt-get install "${APT_INSTALL_FLAGS[@]}" ca-certificates curl wget gnupg lsb-release

# ============================================================================
# PHASE 1: Add all external repos first (minimizes apt update calls)
# ============================================================================
log_step "Phase 1: Setting up package repositories..."

sudo mkdir -p -m 755 /etc/apt/keyrings

# Add repos in parallel using background processes
(
    # GitHub CLI repo
    if [ ! -f /etc/apt/sources.list.d/github-cli.list ] || [ ! -s /etc/apt/keyrings/githubcli-archive-keyring.gpg ]; then
        sudo rm -f /etc/apt/keyrings/githubcli-archive-keyring.gpg
        wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
        sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    fi
) &
PID_GH=$!

(
    # Docker repo
    if [ ! -f /etc/apt/sources.list.d/docker.list ] || [ ! -s /etc/apt/keyrings/docker.gpg ]; then
        sudo rm -f /etc/apt/keyrings/docker.gpg
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    fi
) &
PID_DOCKER=$!

(
    # NodeSource repo (Node.js 20)
    if [ ! -f /etc/apt/sources.list.d/nodesource.list ] || [ ! -s /etc/apt/keyrings/nodesource.gpg ]; then
        sudo rm -f /etc/apt/keyrings/nodesource.gpg
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
        echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list > /dev/null
    fi
) &
PID_NODE=$!

# Wait for all repo setups
REPO_SETUP_FAILED=false
wait $PID_GH || REPO_SETUP_FAILED=true
wait $PID_DOCKER || REPO_SETUP_FAILED=true
wait $PID_NODE || REPO_SETUP_FAILED=true
if [ "$REPO_SETUP_FAILED" = true ]; then
    log_error "Failed to configure one or more package repositories"
    exit 1
fi
log_info "Repositories configured"

# ============================================================================
# PHASE 2: Single apt update + install all packages at once
# ============================================================================
log_step "Phase 2: Installing packages..."

sudo apt-get update -qq

# Optional upgrade (skipped with --fast flag)
if [ "$SKIP_UPGRADE" = false ]; then
    log_info "Running system upgrade (use --fast to skip)..."
    sudo apt-get upgrade "${APT_INSTALL_FLAGS[@]}"
else
    log_warn "Skipping system upgrade (--fast mode)"
fi

# Install ALL apt packages in one command (much faster than multiple calls)
log_info "Installing all packages..."
sudo apt-get install "${APT_INSTALL_FLAGS[@]}" \
    build-essential \
    curl \
    wget \
    git \
    vim \
    htop \
    tmux \
    jq \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    gh \
    nodejs \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

if ! command -v npm &> /dev/null; then
    log_warn "npm not found after nodejs install; installing npm package..."
    sudo apt-get install "${APT_INSTALL_FLAGS[@]}" npm
fi

# Add user to docker group
sudo usermod -aG docker $USER 2>/dev/null || true

log_info "APT packages installed"

# ============================================================================
# PHASE 3: Download binaries in parallel
# ============================================================================
log_step "Phase 3: Installing additional tools..."

# Download kubectl, helm, uv, and npm-based CLIs in parallel
(
    if ! command -v kubectl &> /dev/null; then
        KUBECTL_VERSION=$(curl -sL https://dl.k8s.io/release/stable.txt)
        curl -sLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm -f kubectl
    fi
) &
PID_KUBECTL=$!

(
    if ! command -v helm &> /dev/null; then
        curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash -s -- --no-sudo 2>/dev/null || \
        curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash 2>/dev/null
    fi
) &
PID_HELM=$!

(
    if ! command -v uv &> /dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh 2>/dev/null
    fi
) &
PID_UV=$!

(
    # Install npm-based coding agent CLIs
    NPM_PACKAGES=()
    claude_supports_remote_control || NPM_PACKAGES+=("@anthropic-ai/claude-code@latest")
    command -v codex &> /dev/null || NPM_PACKAGES+=("@openai/codex")
    if [ ${#NPM_PACKAGES[@]} -gt 0 ]; then
        if ! command -v npm &> /dev/null; then
            log_error "npm is not available; cannot install ${NPM_PACKAGES[*]}"
            exit 1
        fi
        log_info "Installing npm packages: ${NPM_PACKAGES[*]}"
        sudo npm install -g "${NPM_PACKAGES[@]}"
    fi
) &
PID_AGENT_CLIS=$!

# Wait for all parallel downloads
log_info "Waiting for parallel installations..."
wait $PID_KUBECTL 2>/dev/null && log_info "kubectl installed" || true
wait $PID_HELM 2>/dev/null && log_info "helm installed" || true
wait $PID_UV 2>/dev/null && log_info "uv installed" || true
if wait $PID_AGENT_CLIS; then
    log_info "coding agent CLIs installed"
else
    log_error "Failed to install coding agent CLIs"
    exit 1
fi

# ============================================================================
# Summary
# ============================================================================
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

log_info ""
log_info "============================================"
log_info "Bootstrap completed in ${ELAPSED} seconds!"
log_info "============================================"
log_info ""
log_info "Installed:"
command -v git &> /dev/null && log_info "  - git $(git --version | cut -d' ' -f3)"
command -v gh &> /dev/null && log_info "  - gh $(gh --version | head -1 | cut -d' ' -f3)"
command -v node &> /dev/null && log_info "  - node $(node -v)"
command -v docker &> /dev/null && log_info "  - docker $(docker --version | cut -d' ' -f3 | tr -d ',')"
command -v kubectl &> /dev/null && log_info "  - kubectl $(kubectl version --client -o json 2>/dev/null | jq -r '.clientVersion.gitVersion' 2>/dev/null || echo 'installed')"
command -v helm &> /dev/null && log_info "  - helm $(helm version --short 2>/dev/null | cut -d'+' -f1)"
command -v claude &> /dev/null && log_info "  - claude-code $(claude --version 2>/dev/null || echo 'installed')"
command -v codex &> /dev/null && log_info "  - codex $(codex --version 2>/dev/null || echo 'installed')"
[ -f "$HOME/.local/bin/uv" ] && log_info "  - uv installed"
log_info ""
log_info "Next steps:"
log_info "1. Run: ${GREEN}bash scripts/setup-terminal.sh${NC} to optimize your terminal"
log_info "2. Run: ${GREEN}bash scripts/setup-microk8s.sh${NC} for Kubernetes with GPU"
log_info "3. Run: ${GREEN}bash scripts/setup-dynamo.sh${NC} for Dynamo and Grove"
log_info ""
log_info "You may need to:"
log_info "- Run: ${GREEN}newgrp docker${NC} to activate docker group"
log_info "- Run: ${GREEN}gh auth login --hostname github.com --git-protocol https --web${NC} and enter the code at https://github.com/login/device"
log_info "- Run: ${GREEN}docker login -u amaddipoti439${NC} to authenticate Docker Hub"
log_info "- Run: ${GREEN}codex login${NC} to authenticate Codex CLI"
log_info "- Run: ${GREEN}source ~/.bashrc${NC} to update PATH"
