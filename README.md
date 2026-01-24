# anish-devbox

Quick setup for GPU VMs with development tools, Kubernetes, and distributed inference.

## TL;DR

```bash
git clone https://github.com/athreesh/anish-devbox ~/anish-devbox && cd ~/anish-devbox
./bootstrap.sh --fast && ./scripts/setup-terminal.sh && source ~/.bashrc
```

## What Gets Installed

| Tool | Description |
|------|-------------|
| **gh** | GitHub CLI for PRs and issues |
| **Node.js 20** | With Claude Code CLI |
| **uv** | Fast Python package manager |
| **Docker** | Container runtime |
| **kubectl + Helm** | Kubernetes tools |
| **fzf, ripgrep, bat, fd** | Modern CLI tools |

## Setup Steps

### 1. Bootstrap (required)

```bash
./bootstrap.sh --fast   # Use --fast to skip apt upgrade
newgrp docker           # Activate docker group
```

### 2. Terminal setup (recommended)

```bash
./scripts/setup-terminal.sh
source ~/.bashrc
```

### 3. Kubernetes + GPU (optional)

```bash
./scripts/setup-microk8s.sh
newgrp microk8s
```

### 4. Dynamo + Grove (optional)

```bash
export HF_TOKEN=your_token
./scripts/setup-dynamo.sh
kubectl apply -f config/dynamo-grove-example.yaml
```

## Makefile

```bash
make fast       # Bootstrap without apt upgrade
make terminal   # Setup terminal
make microk8s   # Setup Kubernetes
make dynamo     # Setup Dynamo/Grove
make all        # Everything
```

## Aliases Installed

**Git:** `gs` `gd` `gl` `gp` `gc` `ga` `gco` `gb`

**Kubernetes:** `k` `kgp` `kgn` `kgs` `kga` `kdp` `kl` `klf`

**Docker:** `d` `dps` `dpsa` `di`

**GPU:** `gpu` `gpus`

**Navigation:** `..` `...` `....` `ll` `la`

## Troubleshooting

<details>
<summary>Docker permission denied</summary>

```bash
sudo usermod -aG docker $USER && newgrp docker
```
</details>

<details>
<summary>Node.js version too old</summary>

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g @anthropic-ai/claude-code
```
</details>

<details>
<summary>GPU not detected</summary>

```bash
nvidia-smi  # Check driver
sudo ubuntu-drivers autoinstall && sudo reboot  # Install if missing
```
</details>

## Structure

```
anish-devbox/
├── bootstrap.sh              # Main setup (Node, gh, Docker, kubectl)
├── scripts/
│   ├── setup-terminal.sh     # Aliases, prompt, CLI tools
│   ├── setup-microk8s.sh     # Kubernetes + GPU
│   ├── setup-dynamo.sh       # Dynamo + Grove
│   └── setup-nix.sh          # Optional Nix setup
├── config/                   # K8s manifests
└── nix/                      # Nix/home-manager configs
```

## License

MIT
