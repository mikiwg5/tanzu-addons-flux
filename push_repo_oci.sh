#!/bin/sh
set -eu

# Configuration
TEST_REGISTRY="harbor-harbor-core:80"
TARGET_PROJECT="platform"
ARTIFACT_NAME="k8s-addons-flux"
TAG="latest"
REPO_PATH="./" # The local directory you want to package and push

HARBOR_USER="admin"
HARBOR_PASSWORD="Harbor12345"

echo "=================================================="
echo "Preparing standalone ORAS utility..."
echo "=================================================="

# 1. Download standalone ORAS binary directly to our working folder
if [ ! -f "./oras" ]; then
    echo "Downloading ORAS binary..."
    wget -qO oras.tar.gz https://github.com/oras-project/oras/releases/download/v1.2.0/oras_1.2.0_linux_amd64.tar.gz || \
    curl -sL -o oras.tar.gz https://github.com/oras-project/oras/releases/download/v1.2.0/oras_1.2.0_linux_amd64.tar.gz
    
    tar -zxf oras.tar.gz oras
    rm oras.tar.gz
    chmod +x ./oras
fi

echo "=================================================="
echo "Authenticating via Harbor Core..."
echo "=================================================="

# 2. Configure local docker config authentication file in home directory
mkdir -p ~/.docker
AUTH=$(echo -n "${HARBOR_USER}:${HARBOR_PASSWORD}" | base64)
echo "{\"auths\":{\"$TEST_REGISTRY\":{\"auth\":\"$AUTH\"}}}" > ~/.docker/config.json

echo "Authentication profiles written."

echo "=================================================="
echo "Pushing Repository Directory as OCI Artifact..."
echo "=================================================="

# 3. Push the directory contents using our secure cluster workspace pod
# We execute this inside the running pod since it bypasses the network wall
kubectl exec -it -n harbor harbor-importer -- /bin/sh -c "
# Create a local copy of oras inside the pod if missing
if [ ! -f /images/oras ]; then
    echo '--> Transferring ORAS to cluster pod workspace...'
    wget -qO /images/oras.tar.gz https://github.com/oras-project/oras/releases/download/v1.2.0/oras_1.2.0_linux_amd64.tar.gz
    tar -zxf /images/oras.tar.gz -C /images/ oras
    rm /images/oras.tar.gz
    chmod +x /images/oras
fi

# Set up authorization inside the pod runtime space
mkdir -p ~/.docker
echo '{\"auths\":{\"$TEST_REGISTRY\":{\"auth\":\"$AUTH\"}}}' > ~/.docker/config.json

echo '--> Executing ORAS OCI artifact push...'
/images/oras push ${TEST_REGISTRY}/${TARGET_PROJECT}/${ARTIFACT_NAME}:${TAG} \
    --insecure \
    ${REPO_PATH}

echo '✅ Success! Artifact pushed to project: ${TARGET_PROJECT}'