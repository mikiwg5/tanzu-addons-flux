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
    
    # If we just applied a base application layer (not a post-config), wait for its HelmReleases to become Ready
    if [[ "${NAME}" != *"-post-configs" ]]; then
      echo "Waiting for HelmReleases in this layer to become Ready..."
      # Extract HelmRelease namespace/name pairs
      HRs=$(flux build kustomization "${NAME}" --path "${DIR}" | awk '
        /^kind: HelmRelease/ { hr=1; in_meta=0; name=""; ns="" }
        hr && /^metadata:/ { in_meta=1 }
        hr && in_meta && /^[[:space:]]+name:/ { name=$2; gsub(/["\x27]/, "", name) }
        hr && in_meta && /^[[:space:]]+namespace:/ { ns=$2; gsub(/["\x27]/, "", ns) }
        hr && /^spec:/ { in_meta=0 }
        /^---/ { if (hr && name && ns) { print ns "/" name }; hr=0; in_meta=0; name=""; ns="" }
        END { if (hr && name && ns) print ns "/" name }
      ')
      for hr in $HRs; do
        ns="${hr%%/*}"
        name="${hr##*/}"
        echo "--> Waiting for HelmRelease $name in namespace $ns..."
        kubectl wait --namespace="$ns" --for=condition=Ready helmrelease/"$name" --timeout=300s || {
          echo "Warning: HelmRelease $name in $ns is not Ready yet. Checking logs or describing it might help."
        }
      done
    fi
  else
    echo "Warning: Kustomization ${NAME} not found in cluster. Skipping..."
  fi
done

echo ""
echo "=================================================="
echo "Local deployment complete!"
echo "=================================================="
