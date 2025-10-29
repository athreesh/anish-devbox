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

# Configuration
NAMESPACE="${NAMESPACE:-vllm-v1-disagg-router}"
RELEASE_VERSION="${DYNAMO_VERSION:-0.5.1}"
HF_TOKEN="${HF_TOKEN:-}"

log_info "Setting up Dynamo and Grove..."
log_info "Namespace: $NAMESPACE"
log_info "Version: $RELEASE_VERSION"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl not found. Please run setup-microk8s.sh first."
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    log_error "helm not found. Please run bootstrap.sh first."
    exit 1
fi

# Prompt for Hugging Face token if not provided
if [ -z "$HF_TOKEN" ]; then
    log_warn "Hugging Face token not set."
    echo -n "Enter your Hugging Face token (or press Enter to skip): "
    read -s HF_TOKEN_INPUT
    echo
    HF_TOKEN="$HF_TOKEN_INPUT"
fi

# Create namespace
log_info "Creating namespace: $NAMESPACE"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Create Hugging Face token secret if provided
if [ -n "$HF_TOKEN" ]; then
    log_info "Creating Hugging Face token secret..."
    kubectl create secret generic hf-token-secret \
        --from-literal=HF_TOKEN="$HF_TOKEN" \
        --namespace="$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    log_info "Hugging Face token secret created."
else
    log_warn "Skipping Hugging Face token secret creation."
    log_warn "You'll need to create it manually later with:"
    log_warn "  kubectl create secret generic hf-token-secret --from-literal=HF_TOKEN=<your-token> -n $NAMESPACE"
fi

# Download and install Dynamo CRDs
log_info "Installing Dynamo CRDs..."
cd /tmp
if [ ! -f "dynamo-crds-${RELEASE_VERSION}.tgz" ]; then
    log_info "Downloading Dynamo CRDs..."
    wget -q "https://helm.ngc.nvidia.com/nvidia/ai-dynamo/charts/dynamo-crds-${RELEASE_VERSION}.tgz" || \
        curl -sLO "https://helm.ngc.nvidia.com/nvidia/ai-dynamo/charts/dynamo-crds-${RELEASE_VERSION}.tgz"
fi

helm upgrade --install dynamo-crds "dynamo-crds-${RELEASE_VERSION}.tgz" --namespace default --wait

# Download and install Dynamo Platform with Grove
log_info "Installing Dynamo Platform with Grove..."
if [ ! -f "dynamo-platform-${RELEASE_VERSION}.tgz" ]; then
    log_info "Downloading Dynamo Platform..."
    wget -q "https://helm.ngc.nvidia.com/nvidia/ai-dynamo/charts/dynamo-platform-${RELEASE_VERSION}.tgz" || \
        curl -sLO "https://helm.ngc.nvidia.com/nvidia/ai-dynamo/charts/dynamo-platform-${RELEASE_VERSION}.tgz"
fi

helm upgrade --install dynamo-platform "dynamo-platform-${RELEASE_VERSION}.tgz" \
    --namespace "$NAMESPACE" \
    --create-namespace \
    --set "grove.enabled=true" \
    --wait

# Verify Grove CRDs
log_info "Verifying Grove installation..."
kubectl get crd | grep grove || log_warn "Grove CRDs not found. Installation may have failed."

# Verify pods are running
log_info "Waiting for Dynamo operator to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=dynamo-operator -n "$NAMESPACE" --timeout=300s || \
    log_warn "Dynamo operator may still be starting. Check with: kubectl get pods -n $NAMESPACE"

# Display status
log_info "Current pod status in namespace $NAMESPACE:"
kubectl get pods -n "$NAMESPACE"

log_info ""
log_info "Dynamo and Grove installation complete!"
log_info ""
log_info "Next steps:"
log_info "1. Deploy a sample DynamoGraphDeployment:"
log_info "   ${GREEN}kubectl apply -f config/dynamo-grove-example.yaml${NC}"
log_info ""
log_info "2. Verify Grove CRDs:"
log_info "   ${GREEN}kubectl get crd | grep grove${NC}"
log_info ""
log_info "3. Check deployment status:"
log_info "   ${GREEN}kubectl get pods -n $NAMESPACE${NC}"
log_info ""
log_info "Useful commands:"
log_info "  kubectl get dynamographdeployment -n $NAMESPACE"
log_info "  kubectl get podclique -n $NAMESPACE"
log_info "  kubectl logs -n $NAMESPACE <pod-name>"
