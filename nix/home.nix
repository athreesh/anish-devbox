{ config, pkgs, ... }:

{
  # Home Manager configuration for GPU development box
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";
  home.stateVersion = "24.11";

  # Packages for GPU/ML development
  home.packages = with pkgs; [
    # Core development tools
    git
    vim
    neovim
    tmux
    htop
    btop
    wget
    curl

    # Shell utilities
    ripgrep
    fd
    bat
    eza
    fzf
    jq
    yq
    tree

    # Container tools
    docker
    docker-compose

    # Kubernetes tools
    kubectl
    kubernetes-helm
    k9s
    kubectx
    stern

    # Python development
    python311
    python311Packages.pip
    python311Packages.virtualenv

    # Node.js (if you want Nix to manage it instead of apt)
    # nodejs_20

    # Monitoring and debugging
    iftop
    iotop
    ncdu
    lsof
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Anish Maddipoti";
    userEmail = "your-email@example.com";  # Update this
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
      core.editor = "vim";
    };
    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
    };
  };

  # Bash configuration
  programs.bash = {
    enable = true;
    shellAliases = {
      # Kubernetes shortcuts
      k = "kubectl";
      kgp = "kubectl get pods";
      kgn = "kubectl get nodes";
      kgs = "kubectl get svc";
      kdp = "kubectl describe pod";
      kl = "kubectl logs";

      # Docker shortcuts
      d = "docker";
      dc = "docker-compose";
      dps = "docker ps";

      # File navigation
      ll = "ls -lah";
      la = "ls -A";
      ".." = "cd ..";
      "..." = "cd ../..";

      # GPU monitoring
      gpus = "watch -n 1 nvidia-smi";
    };

    initExtra = ''
      # Custom prompt with git branch
      parse_git_branch() {
        git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
      }
      export PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[33m\]\$(parse_git_branch)\[\033[00m\]\$ "

      # Kubectl completion
      if command -v kubectl &> /dev/null; then
        source <(kubectl completion bash)
        complete -F __start_kubectl k
      fi

      # Microk8s aliases if installed
      if command -v microk8s &> /dev/null; then
        alias kubectl='microk8s kubectl'
        alias helm='microk8s helm3'
      fi
    '';
  };

  # Vim configuration
  programs.vim = {
    enable = true;
    settings = {
      number = true;
      relativenumber = true;
      expandtab = true;
      tabstop = 2;
      shiftwidth = 2;
    };
    extraConfig = ''
      syntax on
      set mouse=a
      set clipboard=unnamedplus
      set ignorecase
      set smartcase
      set incsearch
      set hlsearch
    '';
  };

  # Tmux configuration
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    keyMode = "vi";
    extraConfig = ''
      # Better split pane bindings
      bind | split-window -h
      bind - split-window -v
      unbind '"'
      unbind %

      # Quick pane switching
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      # Enable mouse mode
      set -g mouse on

      # Start windows and panes at 1, not 0
      set -g base-index 1
      setw -g pane-base-index 1
    '';
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
