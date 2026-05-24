# anish-devbox

Quick setup for GPU VMs with development tools, Kubernetes, and distributed inference.

## TL;DR

```bash
git clone https://github.com/athreesh/anish-devbox ~/anish-devbox
cd ~/anish-devbox
./bootstrap.sh --fast
newgrp docker
gh auth login --hostname github.com --git-protocol https --web
docker login -u amaddipoti439
./scripts/setup-terminal.sh
source ~/.bashrc
```

## What Gets Installed

| Tool | Description |
|------|-------------|
| **gh** | GitHub CLI for PRs and issues |
| **Node.js 20** | Runtime for npm-based CLI tools |
| **Claude Code CLI** | Anthropic coding agent (`claude`) |
| **OpenAI Codex CLI** | OpenAI coding agent (`codex`) |
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

### 2. Authenticate (recommended)

```bash
gh auth login --hostname github.com --git-protocol https --web
docker login -u amaddipoti439
```

The GitHub command starts the browser/device-code flow. When prompted, enter the displayed code at `https://github.com/login/device`.
Docker prompts for the password or access token for `amaddipoti439`.

### 3. Terminal setup (recommended)

```bash
./scripts/setup-terminal.sh
source ~/.bashrc
```

Start a long-running Claude session inside tmux:

```bash
tmux new-session -d -s claude
tmux send-keys -t claude 'claude --dangerously-skip-permissions' C-m
tmux attach -t claude
```

This keeps the tmux pane open if Claude exits with an auth, PATH, or version error.
Use `--dangerously-skip-permissions` only inside trusted repos/VMs; it skips Claude Code permission prompts.

Install personal dotfiles and curated Claude/Codex skills during terminal setup:

```bash
A3SH_DOTFILES=1 ./scripts/setup-terminal.sh
```

This clones or updates private `athreesh/a3sh-dotfiles` under `~/repos`, applies dotfiles with chezmoi, then symlinks curated skills into Claude and Codex. Run `gh auth login --hostname github.com --git-protocol https --web` first if the VM cannot access private GitHub repos.

### 4. Kubernetes + GPU (optional)

```bash
./scripts/setup-microk8s.sh
newgrp microk8s
```

### 5. Dynamo + Grove (optional)

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
sudo npm install -g @anthropic-ai/claude-code@latest @openai/codex
```
</details>

<details>
<summary>Claude command not found</summary>

```bash
./bootstrap.sh --fast
command -v claude && claude --version

# If you only need to repair Claude:
sudo npm install -g @anthropic-ai/claude-code@latest
```
</details>

<details>
<summary>Claude Remote Control is missing or too old</summary>

```bash
claude --version  # Remote Control requires 2.1.51+
sudo npm install -g @anthropic-ai/claude-code@latest
```
</details>

<details>
<summary>Codex CLI is not authenticated</summary>

```bash
codex login
# OR
export OPENAI_API_KEY=<your_key>
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
├── config/                   # Shell, tmux, Claude, prompt, and K8s configs
└── nix/                      # Nix/home-manager configs
```

## License

MIT
