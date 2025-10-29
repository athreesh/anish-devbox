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

log_info "Setting up Nix package manager and home-manager..."

# Check if Nix is already installed
if command -v nix &> /dev/null; then
    log_warn "Nix already installed: $(nix --version)"
    log_info "Skipping Nix installation."
else
    log_info "Installing Nix with flakes support..."

    # Install Nix using the Determinate Systems installer (supports flakes by default)
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

    # Source Nix
    if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi

    log_info "Nix installed successfully."
fi

# Verify Nix is in PATH
if ! command -v nix &> /dev/null; then
    log_error "Nix installation failed or not in PATH."
    log_error "Try sourcing the Nix profile: . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    exit 1
fi

# Install home-manager
log_info "Installing home-manager..."
if ! command -v home-manager &> /dev/null; then
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    nix-shell '<home-manager>' -A install

    log_info "home-manager installed."
else
    log_warn "home-manager already installed."
fi

# Create initial home-manager configuration
log_info "Creating initial home-manager configuration..."
mkdir -p ~/.config/home-manager

if [ ! -f ~/.config/home-manager/home.nix ]; then
    cat > ~/.config/home-manager/home.nix <<'EOF'
{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  home.stateVersion = "24.11";

  # Packages to install
  home.packages = with pkgs; [
    # Development tools
    git
    vim
    tmux
    htop
    jq

    # Node.js and npm are already installed via bootstrap.sh
    # Uncomment if you want Nix to manage them instead:
    # nodejs_20

    # Additional utilities
    ripgrep
    fd
    bat
    eza
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Anish Maddipoti";
    userEmail = "your-email@example.com";  # Update this
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };

  # Bash configuration
  programs.bash = {
    enable = true;
    shellAliases = {
      k = "kubectl";
      ll = "ls -lah";
      ".." = "cd ..";
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
EOF
    log_info "Created ~/.config/home-manager/home.nix"
    log_warn "Please update your email in ~/.config/home-manager/home.nix"
else
    log_warn "home-manager configuration already exists at ~/.config/home-manager/home.nix"
fi

log_info "Nix and home-manager setup complete!"
log_info ""
log_info "Next steps:"
log_info "1. Edit your configuration: ${GREEN}vim ~/.config/home-manager/home.nix${NC}"
log_info "2. Apply configuration: ${GREEN}home-manager switch${NC}"
log_info "3. See example configs in: ${GREEN}./nix/${NC}"
log_info ""
log_info "You may need to reload your shell or source the Nix profile:"
log_info "  ${GREEN}. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh${NC}"
