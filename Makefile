.PHONY: help bootstrap terminal microk8s dynamo nix all fast clean test

help:
	@echo "Available targets:"
	@echo "  bootstrap  - Install base tools (Node, Docker, kubectl, Helm, gh CLI)"
	@echo "  terminal   - Optimize terminal setup (aliases, prompt, tools)"
	@echo "  microk8s   - Setup microk8s with GPU support"
	@echo "  dynamo     - Install Dynamo and Grove"
	@echo "  nix        - Setup Nix and home-manager"
	@echo "  all        - Run bootstrap + terminal + microk8s + dynamo"
	@echo "  fast       - Run bootstrap with --fast flag (skip apt upgrade)"
	@echo "  test       - Test the deployment"
	@echo "  clean      - Remove downloaded files"

bootstrap:
	@echo "Running bootstrap script..."
	chmod +x bootstrap.sh
	./bootstrap.sh

fast:
	@echo "Running fast bootstrap (skipping apt upgrade)..."
	chmod +x bootstrap.sh
	./bootstrap.sh --fast

terminal:
	@echo "Setting up terminal optimizations..."
	chmod +x scripts/setup-terminal.sh
	./scripts/setup-terminal.sh

microk8s:
	@echo "Setting up microk8s..."
	chmod +x scripts/setup-microk8s.sh
	./scripts/setup-microk8s.sh

dynamo:
	@echo "Setting up Dynamo and Grove..."
	chmod +x scripts/setup-dynamo.sh
	./scripts/setup-dynamo.sh

nix:
	@echo "Setting up Nix..."
	chmod +x scripts/setup-nix.sh
	./scripts/setup-nix.sh

all: bootstrap terminal microk8s dynamo
	@echo "Full setup complete!"
	@echo "Next step: kubectl apply -f config/dynamo-grove-example.yaml"

test:
	@echo "Testing Dynamo deployment..."
	kubectl get pods -n vllm-v1-disagg-router
	kubectl get dynamographdeployment -n vllm-v1-disagg-router
	kubectl get podclique -n vllm-v1-disagg-router

clean:
	@echo "Cleaning up downloaded files..."
	rm -f /tmp/dynamo-*.tgz
