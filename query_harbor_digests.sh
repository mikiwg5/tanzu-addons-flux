#!/bin/bash
# query_harbor_digests.sh
# Run from the jump host (inside the cluster network)
# Queries Harbor for the current digests of all image repositories
# and prints sed commands to update the YAML files.

set -e

HARBOR="harbor-harbor-core.harbor.svc.cluster.local"
PROJECT="platform"
USER="admin"
PASS="Harbor12345"

BASE_URL="http://${HARBOR}/api/v2.0/projects/${PROJECT}/repositories"

REPOS=(
  "cert-manager-images"
  "kube-prometheus-images"
  "kyverno-images"
  "trust-manager-images"
  "adcs-issuer-images"
  "external-secrets-images"
  "contour-images"
  "infra-images"
  "splunk-otel-collector-images"
  "alertmanager-images"
  "grafana-operator-images"
  "postgresql-ha-images"
  "tempo-distributed-images"
  "victoria-logs-cluster-images"
  "victoria-metrics-alert-images"
  "victoria-metrics-auth-images"
  "victoria-metrics-cluster-images"
  "idrac-exporter-images"
  "harbor-images"
)

echo "=================================================="
echo "Querying Harbor for current image digests..."
echo "=================================================="

for REPO in "${REPOS[@]}"; do
  echo ""
  echo "--- ${REPO} ---"
  curl -s -u "${USER}:${PASS}" \
    "${BASE_URL}/${REPO}/artifacts?page_size=20" \
    | python3 -c "
import sys, json
data = json.load(sys.stdin)
if not data:
    print('  (no artifacts found)')
else:
    for artifact in data:
        digest = artifact.get('digest', 'n/a')
        tags = [t['name'] for t in artifact.get('tags', [])] if artifact.get('tags') else ['<untagged>']
        for tag in tags:
            print(f'  tag={tag}  digest={digest}')
"
done

echo ""
echo "=================================================="
echo "Done. Copy the digests above and run update_digests.sh"
echo "=================================================="
