#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Ubuntu
if [ ! -f /etc/os-release ] || ! grep -q "Ubuntu" /etc/os-release; then
    log_error "This script is designed for Ubuntu. Detected OS:"
    cat /etc/os-release 2>/dev/null || echo "Unknown"
    exit 1
fi

log_info "Starting anish-devbox setup for GPU VM..."

# Update system
log_info "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install basic utilities
log_info "Installing basic utilities..."
sudo apt install -y \
    build-essential \
    curl \
    wget \
    git \
    vim \
    htop \
    tmux \
    jq \
    ca-certificates \
    gnupg \
    lsb-release

# Install Node.js 20 LTS (using NodeSource)
log_info "Installing Node.js 20 LTS..."
if command -v node &> /dev/null; then
    CURRENT_NODE=$(node -v)
    log_warn "Node.js already installed: $CURRENT_NODE"

    # Check if version is less than 18
    NODE_MAJOR=$(node -v | cut -d'.' -f1 | sed 's/v//')
    if [ "$NODE_MAJOR" -lt 18 ]; then
        log_warn "Node.js version is too old (< v18). Upgrading to v20 LTS..."
        sudo apt remove -y nodejs npm || true
    else
        log_info "Node.js version is sufficient. Skipping installation."
    fi
fi

if ! command -v node &> /dev/null || [ "$NODE_MAJOR" -lt 18 ]; then
    # Download and execute NodeSource setup script
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs

    # Verify installation
    NODE_VERSION=$(node -v)
    NPM_VERSION=$(npm -v)
    log_info "Node.js installed: $NODE_VERSION"
    log_info "npm installed: $NPM_VERSION"
fi

# Install Claude Code CLI
log_info "Installing Claude Code CLI..."
if command -v claude &> /dev/null; then
    log_warn "Claude Code CLI already installed: $(claude --version || echo 'unknown version')"
else
    sudo npm install -g @anthropic-ai/claude-code
    log_info "Claude Code CLI installed successfully"
fi

# Install Docker (required for microk8s alternatives and general use)
log_info "Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add user to docker group
    sudo usermod -aG docker $USER
    log_info "Docker installed. You may need to log out and back in for docker group membership to take effect."
else
    log_info "Docker already installed: $(docker --version)"
fi

# Install kubectl
log_info "Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    log_info "kubectl installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
    log_info "kubectl already installed: $(kubectl version --client --short 2>/dev/null || echo 'version check skipped')"
fi

# Install Helm
log_info "Installing Helm..."
if ! command -v helm &> /dev/null; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    log_info "Helm installed: $(helm version --short)"
else
    log_info "Helm already installed: $(helm version --short)"
fi

log_info "Bootstrap installation complete!"
log_info ""
log_info "Next steps:"
log_info "1. Run: ${GREEN}./scripts/setup-microk8s.sh${NC} to install Kubernetes with GPU support"
log_info "2. Run: ${GREEN}./scripts/setup-dynamo.sh${NC} to install Dynamo and Grove"
log_info "3. If you want full Nix-based config: ${GREEN}./scripts/setup-nix.sh${NC}"
log_info ""
log_info "You may need to:"
log_info "- Log out and back in for docker group changes to take effect"
log_info "- Run: ${GREEN}newgrp docker${NC} to activate docker group in current session"
