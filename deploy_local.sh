#!/bin/bash
# deploy_local.sh
# Run from the root of tanzu-addons-flux on the jump box.
# Builds and applies each layer locally, performing Flux postBuild substitution.

set -e

echo "=================================================="
echo "Starting local client-side deployment..."
echo "=================================================="

# Array of Kustomization names and their corresponding local directories
LAYERS=(
  "common-apps:./common"
  "common-apps-post-configs:./common/post-configs"
  "extras-apps:./extras"
  "extras-apps-post-configs:./extras/post-configs"
  "observability-apps:./observability"
  "observability-agents-apps:./observability-agents"
  "observability-agents-post-configs:./observability-agents/post-configs"
)

for LAYER in "${LAYERS[@]}"; do
  NAME="${LAYER%%:*}"
  DIR="${LAYER##*:}"
  
  echo ""
  echo "--------------------------------------------------"
  echo "Building and applying layer: ${NAME} (from ${DIR})"
  echo "--------------------------------------------------"
  
  # Check if the Kustomization exists in the cluster
  if kubectl get kustomization "${NAME}" -n flux-system &>/dev/null; then
    flux build kustomization "${NAME}" --path "${DIR}" | kubectl apply -f -
  else
    echo "Warning: Kustomization ${NAME} not found in cluster. Skipping..."
  fi
done

echo ""
echo "=================================================="
echo "Local deployment complete!"
echo "=================================================="
