#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_info "Setting up microk8s with GPU support..."

# Check for NVIDIA GPU
if ! command -v nvidia-smi &> /dev/null; then
    log_warn "nvidia-smi not found. GPU support may not be available."
    log_warn "If you have an NVIDIA GPU, install the NVIDIA drivers first."
else
    log_info "NVIDIA GPU detected:"
    nvidia-smi --query-gpu=name --format=csv,noheader
fi

# Install microk8s
log_info "Installing microk8s via snap..."
if command -v microk8s &> /dev/null; then
    log_warn "microk8s already installed: $(microk8s version)"
else
    sudo snap install microk8s --classic --channel=1.31/stable

    # Add user to microk8s group
    sudo usermod -a -G microk8s $USER

    log_info "microk8s installed. Waiting for it to be ready..."
    sudo microk8s status --wait-ready
fi

# Create kubectl alias
log_info "Setting up kubectl alias..."
if ! grep -q "alias kubectl='microk8s kubectl'" ~/.bashrc; then
    echo "alias kubectl='microk8s kubectl'" >> ~/.bashrc
    echo "alias k='microk8s kubectl'" >> ~/.bashrc
fi

if [ -f ~/.zshrc ] && ! grep -q "alias kubectl='microk8s kubectl'" ~/.zshrc; then
    echo "alias kubectl='microk8s kubectl'" >> ~/.zshrc
    echo "alias k='microk8s kubectl'" >> ~/.zshrc
fi

# Enable essential addons
log_info "Enabling microk8s addons..."

# Enable DNS first (required by many other services)
sudo microk8s enable dns

# Enable storage
sudo microk8s enable hostpath-storage

# Enable Helm
sudo microk8s enable helm3

# Enable GPU support if NVIDIA drivers are available
if command -v nvidia-smi &> /dev/null; then
    log_info "Enabling GPU support..."
    sudo microk8s enable gpu

    # Verify GPU operator is running
    log_info "Waiting for GPU operator to be ready (this may take a few minutes)..."
    sudo microk8s kubectl wait --for=condition=ready pod -l app=nvidia-device-plugin-daemonset -n gpu-operator-resources --timeout=300s || \
        log_warn "GPU operator pods may still be starting. Check with: microk8s kubectl get pods -n gpu-operator-resources"
else
    log_warn "Skipping GPU addon (no NVIDIA drivers detected)"
fi

# Setup kubeconfig for standard kubectl (if installed)
if command -v kubectl &> /dev/null; then
    log_info "Configuring kubeconfig for standard kubectl..."
    sudo microk8s config > ~/.kube/config || mkdir -p ~/.kube && sudo microk8s config > ~/.kube/config
    chmod 600 ~/.kube/config
fi

# Verify installation
log_info "Verifying microk8s installation..."
sudo microk8s kubectl get nodes
sudo microk8s kubectl get pods -A

log_info "microk8s setup complete!"
log_info ""
log_info "Important notes:"
log_info "1. You may need to log out and back in for group changes to take effect"
log_info "2. Or run: ${GREEN}newgrp microk8s${NC} to activate the group in current session"
log_info "3. Use: ${GREEN}microk8s kubectl${NC} or just ${GREEN}kubectl${NC} (after reloading shell)"
log_info "4. Aliases added: ${GREEN}k${NC} for kubectl"
log_info ""
log_info "Useful commands:"
log_info "  microk8s status          - Check status"
log_info "  microk8s kubectl get all - List all resources"
log_info "  microk8s stop            - Stop microk8s"
log_info "  microk8s start           - Start microk8s"
