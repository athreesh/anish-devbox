# Quick Start Guide

## One-Command Setup

```bash
# Clone and run everything
git clone <your-repo-url> ~/anish-devbox && cd ~/anish-devbox && make all
```

## Or Step-by-Step

### Fresh GPU VM → Fully Configured (3 commands)

```bash
# 1. Bootstrap (Node 20, Claude Code, Codex, Docker, kubectl, Helm)
./bootstrap.sh

# 2. Kubernetes + GPU
./scripts/setup-microk8s.sh

# 3. Dynamo + Grove
export HF_TOKEN=hf_...  # Your Hugging Face token
./scripts/setup-dynamo.sh
```

## Deploy Example Workload

```bash
# Deploy Qwen 0.6B with disaggregated serving
kubectl apply -f config/dynamo-grove-example.yaml

# Watch it come up
watch kubectl get pods -n vllm-v1-disagg-router

# Test it
kubectl port-forward svc/dynamo-grove-frontend 8000:8000 -n vllm-v1-disagg-router &
curl http://localhost:8000/v1/models
```

## Common Issues & Fixes

### "Unexpected token '?'" when running `claude`
```bash
# Node version too old
node -v  # Should be v20.x.x
./bootstrap.sh  # Re-run to upgrade Node
```

### "claude remote-control" is unavailable
```bash
# Re-run bootstrap to upgrade Claude Code to a Remote Control-capable version
./bootstrap.sh --fast
claude --version  # Should be 2.1.51+
```

### "codex: command not found"
```bash
# Re-run bootstrap to install the OpenAI Codex CLI
./bootstrap.sh --fast
```

### "permission denied" for docker
```bash
newgrp docker  # Activate group immediately
# OR log out and back in
```

### "kubectl: command not found" after microk8s install
```bash
source ~/.bashrc  # or ~/.zshrc
# OR
alias kubectl='microk8s kubectl'
```

### GPU not available in cluster
```bash
# Check driver
nvidia-smi

# If missing, install driver
sudo ubuntu-drivers autoinstall
sudo reboot

# Then re-run
./scripts/setup-microk8s.sh
```

## Essential Commands

```bash
# GPU monitoring
watch -n 1 nvidia-smi

# K8s monitoring
watch kubectl get pods -A
kubectl logs -f <pod-name> -n vllm-v1-disagg-router

# microk8s control
microk8s status
microk8s stop
microk8s start

# Clean restart
microk8s reset  # WARNING: Deletes everything
```

## What Gets Installed?

| Component | Where | Command |
|-----------|-------|---------|
| Node.js 20 LTS | System | `node -v` |
| Claude Code CLI | npm global | `claude` |
| OpenAI Codex CLI | npm global | `codex` |
| Docker | System | `docker ps` |
| kubectl | /usr/local/bin | `kubectl version` |
| Helm | /usr/local/bin | `helm version` |
| microk8s | snap | `microk8s status` |
| Dynamo | Helm chart | `kubectl get crd \| grep dynamo` |
| Grove | Helm chart | `kubectl get crd \| grep grove` |

## Time Estimates

- **bootstrap.sh**: ~5-10 minutes
- **setup-microk8s.sh**: ~5-10 minutes (longer with GPU operator)
- **setup-dynamo.sh**: ~3-5 minutes
- **Full deployment**: ~15-25 minutes

## Advanced: Nix Setup

For declarative, reproducible environments:

```bash
./scripts/setup-nix.sh
cp nix/home.nix ~/.config/home-manager/
# Edit email in config
vim ~/.config/home-manager/home.nix
home-manager switch
```

## Need Help?

See [README.md](README.md) for detailed documentation and troubleshooting.
