#!/bin/bash
set -e

# --- Configuration ---
# Prompt for Harbor Username if not already set
if [ -z "$HARBOR_USER" ]; then
    read -p "Enter Harbor username: " HARBOR_USER
fi

# Prompt for Harbor Password if not already set
if [ -z "$HARBOR_PASSWORD" ]; then
    read -sp "Enter Harbor password: " HARBOR_PASSWORD
    echo ""
fi

# Pre-configured with the Tanzu node IP and HTTPS NodePort
HARBOR_REGISTRY='127.0.0.1:9443'

HARBOR_PROJECT='platform'
ARTIFACT_NAME='k8s-addons-flux'
REPO_PATH='./'

# --- 1. Install ORAS locally if not present ---
if ! command -v oras &> /dev/null; then
    echo "ORAS not found in PATH, installing ORAS v1.2.0 locally..."
    curl -sLO https://github.com/oras-project/oras/releases/download/v1.2.0/oras_1.2.0_linux_amd64.tar.gz
    tar -zxf oras_1.2.0_linux_amd64.tar.gz oras
    # Add current directory to PATH so we can run oras
    export PATH="$PATH:$(pwd)"
    rm -f oras_1.2.0_linux_amd64.tar.gz
    echo "ORAS installed locally in $(pwd)."
fi

# --- 2. Gather Git Metadata ---
if [ ! -d ".git" ]; then
    echo "Error: Must be run inside a Git repository."
    exit 1
fi

CI_COMMIT_SHORT_SHA=$(git rev-parse --short HEAD)
CI_COMMIT_SHA=$(git rev-parse HEAD)
CI_PROJECT_URL=$(git config --get remote.origin.url || echo "unknown")

echo "Short SHA: ${CI_COMMIT_SHORT_SHA}"
echo "Full SHA: ${CI_COMMIT_SHA}"
echo "Project URL: ${CI_PROJECT_URL}"

# --- 3. Login to Harbor ---
echo "Logging in to Harbor registry at ${HARBOR_REGISTRY} as ${HARBOR_USER}..."
oras login -u "${HARBOR_USER}" -p "${HARBOR_PASSWORD}" "${HARBOR_REGISTRY}" --insecure

# --- 4. Push OCI Artifact ---
echo "Pushing OCI artifact..."
oras push "${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${ARTIFACT_NAME}:${CI_COMMIT_SHORT_SHA}" \
  --insecure \
  --annotation "org.opencontainers.image.source=${CI_PROJECT_URL}" \
  --annotation "org.opencontainers.image.revision=${CI_COMMIT_SHA}" \
  "${REPO_PATH}"

# --- 5. Tag as Latest ---
echo "Tagging artifact as 'latest'..."
oras tag "${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${ARTIFACT_NAME}:${CI_COMMIT_SHORT_SHA}" latest --insecure

echo "Successfully pushed and tagged ${ARTIFACT_NAME}:${CI_COMMIT_SHORT_SHA} as latest!"