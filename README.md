# anish-devbox

Quick setup for GPU VMs with Kubernetes, Dynamo, Grove, and development tools.

## Overview

This repository provides a fast, automated setup for landing in a fresh GPU VM (Ubuntu) with everything pre-configured:

- **GitHub CLI (gh)** for Git operations and PR workflows
- **Node.js 20 LTS** with Claude Code CLI
- **uv** - fast Python package manager
- **microk8s** with GPU support
- **Dynamo & Grove** for distributed inference
- **Docker**, **kubectl**, **Helm**
- **Terminal optimizations** with useful aliases and completions
- Optional **Nix** configuration for declarative environment management

## Quick Start

### 1. Clone this repo

```bash
git clone https://github.com/athreesh/anish-devbox ~/anish-devbox
cd ~/anish-devbox
```

### 2. Run the bootstrap script

```bash
chmod +x bootstrap.sh scripts/*.sh
./bootstrap.sh
```

**Speed tip:** Use `--fast` to skip the system upgrade (saves significant time on fresh VMs):
```bash
./bootstrap.sh --fast
```

This installs:
- System utilities (curl, wget, git, vim, tmux, etc.)
- **GitHub CLI (gh)** for Git operations and PR workflows
- **Node.js 20 LTS** (fixes the v12 engine mismatch issue)
- **Claude Code CLI** via npm
- **uv** - fast Python package manager
- Docker with user permissions
- kubectl and Helm

**Important:** After the bootstrap script completes, you may need to:
```bash
# Activate docker group in current session
newgrp docker

# Or log out and back in for permanent effect
```

### 3. Optimize your terminal (recommended)

```bash
./scripts/setup-terminal.sh
```

This sets up:
- Modern CLI tools (fzf, bat, ripgrep, fd)
- Useful aliases for git, kubectl, docker
- Custom prompt with git branch display
- Shell completions for kubectl, gh, docker
- Better history settings

### 4. Setup Kubernetes with GPU support

```bash
./scripts/setup-microk8s.sh
```

This installs and configures:
- microk8s with essential addons (dns, storage, helm3)
- GPU operator (if NVIDIA drivers detected)
- kubectl aliases and kubeconfig

**Note:** After this step, reload your shell or run:
```bash
newgrp microk8s
source ~/.bashrc  # or ~/.zshrc
```

### 5. Setup Dynamo & Grove

```bash
export HF_TOKEN=your_huggingface_token  # Optional: set before running
./scripts/setup-dynamo.sh
```

This installs:
- Dynamo CRDs and operator
- Grove for distributed inference
- Example DynamoGraphDeployment configuration

### 6. Deploy example workload

```bash
# Make sure HF token secret is created first
kubectl create secret generic hf-token-secret \
  --from-literal=HF_TOKEN=<your_token> \
  -n vllm-v1-disagg-router

# Deploy the example
kubectl apply -f config/dynamo-grove-example.yaml

# Check status
kubectl get pods -n vllm-v1-disagg-router
```

### 7. Test the deployment

```bash
# Port-forward the frontend
kubectl port-forward svc/dynamo-grove-frontend 8000:8000 -n vllm-v1-disagg-router

# In another terminal, test the endpoint
curl http://localhost:8000/v1/models
```

## Optional: Nix Setup

For declarative, reproducible environment management:

```bash
./scripts/setup-nix.sh
```

Then:

```bash
# Edit your home-manager config
vim ~/.config/home-manager/home.nix

# Or use the provided config
cp nix/home.nix ~/.config/home-manager/home.nix

# Update your email in the config
vim ~/.config/home-manager/home.nix

# Apply the configuration
home-manager switch
```

### Using Nix Flakes

```bash
# Copy flake configuration
cp nix/flake.nix ~/.config/home-manager/

# Build and activate (replace 'anish' with your username)
nix run home-manager/master -- switch --flake ~/.config/home-manager#anish
```

## Repository Structure

```
anish-devbox/
├── bootstrap.sh                 # Main setup script (Node, gh, Docker, kubectl, etc.)
├── scripts/
│   ├── setup-terminal.sh       # Terminal optimizations (aliases, prompt, tools)
│   ├── setup-microk8s.sh       # Kubernetes with GPU support
│   ├── setup-dynamo.sh         # Dynamo & Grove installation
│   └── setup-nix.sh            # Optional Nix package manager
├── config/
│   └── dynamo-grove-example.yaml  # Example DynamoGraphDeployment
├── nix/
│   ├── home.nix                # Home-manager configuration
│   └── flake.nix               # Nix flake for reproducible builds
└── README.md
```

## Makefile Targets

```bash
make help       # Show available targets
make bootstrap  # Install base tools
make fast       # Fast bootstrap (skip apt upgrade)
make terminal   # Setup terminal optimizations
make microk8s   # Setup Kubernetes with GPU
make dynamo     # Setup Dynamo and Grove
make nix        # Setup Nix package manager
make all        # Run everything
make test       # Test the deployment
make clean      # Cleanup
```

## Troubleshooting

### Node.js version issues

If you see errors like `Unexpected token '?'` when running `claude`:

```bash
# Check Node version (must be >= 18)
node -v

# If too old, the bootstrap script will upgrade it
# Or manually install Node 20 LTS:
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Reinstall Claude Code CLI
sudo npm install -g @anthropic-ai/claude-code
```

### Docker permission denied

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Activate in current session
newgrp docker

# Or log out and back in
```

### microk8s not in PATH

```bash
# Add to shell config
echo "alias kubectl='microk8s kubectl'" >> ~/.bashrc
echo "alias k='microk8s kubectl'" >> ~/.bashrc
source ~/.bashrc
```

### GPU not detected

```bash
# Check NVIDIA driver
nvidia-smi

# If not installed, install NVIDIA drivers first:
# Ubuntu with NVIDIA GPU
sudo ubuntu-drivers devices
sudo ubuntu-drivers autoinstall
sudo reboot

# Then run setup-microk8s.sh again
```

### Dynamo pods not starting

```bash
# Check if HF token secret exists
kubectl get secret hf-token-secret -n vllm-v1-disagg-router

# If not, create it:
kubectl create secret generic hf-token-secret \
  --from-literal=HF_TOKEN=<your_token> \
  -n vllm-v1-disagg-router

# Check pod logs
kubectl logs -n vllm-v1-disagg-router <pod-name>

# Check GPU availability in cluster
kubectl get nodes -o json | jq '.items[].status.capacity'
```

## Useful Commands

### Kubernetes

```bash
# View all resources
kubectl get all -A

# Watch pods
watch kubectl get pods -n vllm-v1-disagg-router

# View logs
kubectl logs -f -n vllm-v1-disagg-router <pod-name>

# Describe pod
kubectl describe pod <pod-name> -n vllm-v1-disagg-router

# Inspect PodClique
kubectl get podclique -n vllm-v1-disagg-router -o yaml
```

### GPU Monitoring

```bash
# Watch GPU usage
watch -n 1 nvidia-smi

# Check GPU in Kubernetes
kubectl get nodes -o json | jq '.items[].status.capacity."nvidia.com/gpu"'
```

### microk8s

```bash
# Status
microk8s status

# Stop/Start
microk8s stop
microk8s start

# Enable/disable addons
microk8s enable <addon>
microk8s disable <addon>

# Reset (WARNING: deletes everything)
microk8s reset
```

## Customization

### Change Dynamo version

```bash
export DYNAMO_VERSION=0.5.2
./scripts/setup-dynamo.sh
```

### Change namespace

```bash
export NAMESPACE=my-custom-namespace
./scripts/setup-dynamo.sh
```

### Modify the example deployment

Edit `config/dynamo-grove-example.yaml` to change:
- Model (default: Qwen/Qwen3-0.6B)
- Replica counts
- GPU allocation
- Worker types (prefill/decode)

## References

- [Dynamo Documentation](https://docs.nvidia.com/ai-dynamo/)
- [Grove GitHub](https://github.com/ai-dynamo/grove)
- [microk8s Documentation](https://microk8s.io/docs)
- [Nix Home Manager](https://github.com/nix-community/home-manager)

## Contributing

Feel free to customize and adapt this setup for your needs. This is a personal development environment configuration.

## License

MIT
