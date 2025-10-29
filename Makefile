.PHONY: help bootstrap microk8s dynamo nix all clean test

help:
	@echo "Available targets:"
	@echo "  bootstrap  - Install base tools (Node, Docker, kubectl, Helm)"
	@echo "  microk8s   - Setup microk8s with GPU support"
	@echo "  dynamo     - Install Dynamo and Grove"
	@echo "  nix        - Setup Nix and home-manager"
	@echo "  all        - Run bootstrap + microk8s + dynamo"
	@echo "  test       - Test the deployment"
	@echo "  clean      - Remove downloaded files"

bootstrap:
	@echo "Running bootstrap script..."
	chmod +x bootstrap.sh
	./bootstrap.sh

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

all: bootstrap microk8s dynamo
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
