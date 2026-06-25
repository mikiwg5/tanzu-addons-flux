#!/usr/bin/env bash
# =============================================================================
# sync-images.sh — Pull all images from production Harbor and push to test Harbor
#
# Usage:
#   chmod +x sync-images.sh
#   ./sync-images.sh \
#     --prod-harbor harbor.safaricomet.net \
#     --prod-user admin \
#     --prod-pass YOUR_PROD_PASSWORD \
#     --test-harbor 100.100.2.75:30443 \
#     --test-user admin \
#     --test-pass YOUR_TEST_PASSWORD
#
# Requirements: docker CLI on the machine running this script
# Run this from a machine that can reach BOTH Harbor instances
# =============================================================================
set -euo pipefail

# --------------------------------------------------------------------------
# Argument parsing
# --------------------------------------------------------------------------
usage() {
  echo ""
  echo "Usage: ./sync-images.sh"
  echo "  --prod-harbor  <production harbor host>   e.g. harbor.safaricomet.net"
  echo "  --prod-user    <production harbor user>   e.g. admin"
  echo "  --prod-pass    <production harbor password>"
  echo "  --test-harbor  <test harbor host:port>    e.g. 100.100.2.75:30443"
  echo "  --test-user    <test harbor user>         e.g. admin"
  echo "  --test-pass    <test harbor password>"
  echo ""
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prod-harbor) PROD_HARBOR="$2"; shift 2 ;;
    --prod-user)   PROD_USER="$2";   shift 2 ;;
    --prod-pass)   PROD_PASS="$2";   shift 2 ;;
    --test-harbor) TEST_HARBOR="$2"; shift 2 ;;
    --test-user)   TEST_USER="$2";   shift 2 ;;
    --test-pass)   TEST_PASS="$2";   shift 2 ;;
    --help|-h)     usage ;;
    *) echo "Unknown argument: $1"; usage ;;
  esac
done

MISSING=()
[[ -z "${PROD_HARBOR:-}" ]] && MISSING+=(--prod-harbor)
[[ -z "${PROD_USER:-}"   ]] && MISSING+=(--prod-user)
[[ -z "${PROD_PASS:-}"   ]] && MISSING+=(--prod-pass)
[[ -z "${TEST_HARBOR:-}" ]] && MISSING+=(--test-harbor)
[[ -z "${TEST_USER:-}"   ]] && MISSING+=(--test-user)
[[ -z "${TEST_PASS:-}"   ]] && MISSING+=(--test-pass)
[[ ${#MISSING[@]} -gt 0 ]] && { echo "Missing: ${MISSING[*]}"; usage; }

# --------------------------------------------------------------------------
# Login to both registries
# --------------------------------------------------------------------------
echo "Logging in to production Harbor ($PROD_HARBOR)..."
echo "$PROD_PASS" | docker login "$PROD_HARBOR" -u "$PROD_USER" --password-stdin

echo "Logging in to test Harbor ($TEST_HARBOR)..."
echo "$TEST_PASS" | docker login "$TEST_HARBOR" -u "$TEST_USER" --password-stdin

# --------------------------------------------------------------------------
# Helper: pull from prod, tag, push to test under /oss/
# --------------------------------------------------------------------------
sync_image() {
  local repo="$1"      # e.g. platform/kube-prometheus-images
  local digest="$2"    # e.g. sha256:abc123...

  local repo_name
  repo_name=$(echo "$repo" | cut -d'/' -f2)  # strip "platform/" prefix

  local src="${PROD_HARBOR}/${repo}@${digest}"
  local dst="${TEST_HARBOR}/oss/${repo_name}"

  echo ""
  echo "--- Syncing ${repo_name}@${digest:0:19}..."
  docker pull "$src"
  docker tag "$src" "$dst"
  docker push "$dst"
  echo "    ✅ Done: $dst"
}

# --------------------------------------------------------------------------
# All images from the repo
# --------------------------------------------------------------------------

# kube-prometheus-images
sync_image "platform/kube-prometheus-images" "sha256:50bcca286519e8f96a3b57c7570762a08398c3ae5f57875dd15e0f3e118b9ed3"
sync_image "platform/kube-prometheus-images" "sha256:33096ddabe7043b574aac673839d4d6116f67d5b9a9eacb18a9a4f813b32ab08"
sync_image "platform/kube-prometheus-images" "sha256:d085c8ee753adfb3f4c6817e352899fe26dab6464bda13cc345bea60372d96a6"
sync_image "platform/kube-prometheus-images" "sha256:653097383091e922aea65277d4a3525d76e22c0124719902d7ee0e6f95c2f953"
sync_image "platform/kube-prometheus-images" "sha256:9b23077204b4c3240b9075875573bfbed1805261f3b6248d48d2a65160bc6e0b"
sync_image "platform/kube-prometheus-images" "sha256:1c5d23f84cbc84b870e64bbfefb4bcf62a0a08fe94e1f78987261728f7efe7bb"
sync_image "platform/kube-prometheus-images" "sha256:ea1285dffce8a938ef356908d1be741da594310c8dced79b870d66808cb12b0f"

# kyverno-images
sync_image "platform/kyverno-images" "sha256:701bc72dea299c41b26593d99bcb98f41ff606fccbcaf184b180ca0eb277e94b"
sync_image "platform/kyverno-images" "sha256:584c3aa5ea2787155c186d156a85c380db220a8c886c01aac511b99880290010"
sync_image "platform/kyverno-images" "sha256:17fbe06fa531c25233db385db7d8efa7a548d35710040c481437352fd3220a0f"
sync_image "platform/kyverno-images" "sha256:a226250087202062d7c0644bb3f9331068b2a3db414f9153e95c0312cde06bb1"
sync_image "platform/kyverno-images" "sha256:3fc886f4fe29eabab6e83260584db3bd23a53486a334d73c9828599728998bf3"
sync_image "platform/kyverno-images" "sha256:e0f7b72c415089be1f08bfdaf12e433cbb24434ae100aa14e72bb7f4121299ce"
sync_image "platform/kyverno-images" "sha256:2270989dd9b79f88bb83750bf7fd006189284d3c90c93a0a40be4ab566d65a8a"
sync_image "platform/kyverno-images" "sha256:55e97e8084e83bba2f9498cda53f989dc1dbbe8cf655af200f5e1bebd90df5bb"

# cert-manager-images
sync_image "platform/cert-manager-images" "sha256:6802c6afea2da91f5782880b79008179bb98147a23ce00f3cab5ba799807b5d6"
sync_image "platform/cert-manager-images" "sha256:631ba2b3bf7be0bd0d446b8bfcbeb56f8fe735cd02a267567a8d94682d03165b"
sync_image "platform/cert-manager-images" "sha256:a896ff5d8029e5a040643935089ef0466fe0c1f6b2fe591f342994c53aada6e2"
sync_image "platform/cert-manager-images" "sha256:373e3acd7b96c87a574f9234bb4fbfd576e3205c502d6da5dade41165c9dc828"

# trust-manager-images
sync_image "platform/trust-manager-images" "sha256:b38f8443f651f2a1ccd233dfe2bb16932b8b13107fd5ba0878179c11156495ec"
sync_image "platform/trust-manager-images" "sha256:36062665587556ecfab32ef430544bde9e251d15bacbe7dd23b1680026f69f8a"

# external-secrets-images
sync_image "platform/external-secrets-images" "sha256:f0ac6763be56632989263a115ec4246210815051ed3f38cd2ed39d8357957729"

# contour-images
sync_image "platform/contour-images" "sha256:beb9c82dc35187a794aafb7e0ccdd38b13114ae35d1dcba3c4f7601db1bb784c"
sync_image "platform/contour-images" "sha256:cdd2b55ac98dc9ddfc026cb3988453424861773886aea7d24242702c90c44b1b"

# splunk-otel-collector-images
sync_image "platform/splunk-otel-collector-images" "sha256:870e815c3a50dd0f6b40efddb319c72c32c3ee340b5a3e8945904232ccd12f44"
sync_image "platform/splunk-otel-collector-images" "sha256:8737d1ad4672e19b52baef59a229be77c23d32522f802466430ce9500ef0e430"
sync_image "platform/splunk-otel-collector-images" "sha256:0f7fd5c59e12e225d2c8882e996d2a3e661dab632b0be0ac1d6504b47265443c"
sync_image "platform/splunk-otel-collector-images" "sha256:ea7bdc09a4929c8cad2b84b06ea4455721e75d4b86aa3dddf41f29b4817db358"
sync_image "platform/splunk-otel-collector-images" "sha256:88092004aad540b2e49dfd3083843b7da20ae08878762d05516f7dda7f1ea34e"

# container-storage-modules-images
sync_image "platform/container-storage-modules-images" "sha256:db4c4bee943c6256ccd28138a1ce418cf461a55a74d93768a738f67c0261c34b"
sync_image "platform/container-storage-modules-images" "sha256:3a8f2f0311b68e7f208ce67c9fd4c52d6fed7a025aa4dd745d7a09c5d0b9168a"
sync_image "platform/container-storage-modules-images" "sha256:013043c3893ce67ffba2d4772dc6ee6bf26a6c857b587d32ae4fc839dd9f9073"
sync_image "platform/container-storage-modules-images" "sha256:fd3455285cd0a8771594d7e441da0fdd77e9a843a6b75058a2d1e14326e120dd"
sync_image "platform/container-storage-modules-images" "sha256:47ab8aebebdc59316004ba8d51a903637d808f4e62a6d0f599ed3c2483cea901"
sync_image "platform/container-storage-modules-images" "sha256:dda7d9053f91ede34fd9d2f465c84817043e5037aa8ea1a20d2c6875b8fa4a44"
sync_image "platform/container-storage-modules-images" "sha256:f032a0ca4c699eebe403988a0e217c3dfc82e2cee8b7d9d247a493e5a2425f24"
sync_image "platform/container-storage-modules-images" "sha256:7beede062248204a54ed6813b2d2fb84a99db6d56a824eed483ed1d7965ea6a1"
sync_image "platform/container-storage-modules-images" "sha256:706f7cdcccd30ca5f0e94d548e2e0c658f69c0fe4b68a5bf37818a04ca618d3d"
sync_image "platform/container-storage-modules-images" "sha256:81d32545fb1b2c319bfeb36a70db4b4d3aea9c51c0574b209b8f64750b32d2f0"

# alertmanager-images
sync_image "platform/alertmanager-images" "sha256:d163d8eeab29cdc2e60e60510b19c328d49f090dc7adc27cb89289748c3b6a1e"
sync_image "platform/alertmanager-images" "sha256:220da6995a919b9ee6e0d3da7ca5f09802f3088007af56be22160314d2485b54"

# victoria-metrics-cluster-images
sync_image "platform/victoria-metrics-cluster-images" "sha256:70839fbd67fab6cc00f647a6370d7f0587aabb24cc18da8b90b5b24b6e647622"
sync_image "platform/victoria-metrics-cluster-images" "sha256:3b89721d28fad348beff693e94afdb425230fed22f1c56ae6229211b7258b442"
sync_image "platform/victoria-metrics-cluster-images" "sha256:6d5735396c0cff693a3c1de6190a86c2bb19b1aff0f16f1c7396904e5974d425"

# victoria-logs-cluster-images
sync_image "platform/victoria-logs-cluster-images" "sha256:d43f95621b946ab6aecdb42b85cbfc6760888617ed281dcbdc9780ce01d75d5e"

# victoria-metrics-auth-images
sync_image "platform/victoria-metrics-auth-images" "sha256:9e72a798bd00fe4b3ada83ffef10e0dfde73c2fd5249cd742b831a492718c79b"

# victoria-metrics-alert-images
sync_image "platform/victoria-metrics-alert-images" "sha256:addc28679f146199c048f571aededcdde362394a862b6ab8b19d65f02e6ed3bb"

# tempo-distributed-images
sync_image "platform/tempo-distributed-images" "sha256:6d1f21c5d2ca33a96524a408a5d5b4162a3a319ba5170a46ee0c5ecf5802ab27"
sync_image "platform/tempo-distributed-images" "sha256:b025a4a4db0a58cc94e2abfab59751f92d74ab8cc024d2e6025ba7efb87bbaff"
sync_image "platform/tempo-distributed-images" "sha256:aac456c35cd29635b5501fefac58a2e954752006c9d159fbf520dd785e09cbba"
sync_image "platform/tempo-distributed-images" "sha256:2d3785a0ddb28c083298261c2a989ea108435078234e005fc6e3ec8f313f5a3b"

# postgresql-ha-images
sync_image "platform/postgresql-ha-images" "sha256:d7f10fce8a7cd60d33f6f5a6b2ec52e87221d45d99eef4f0400cb1bbbdc1d027"
sync_image "platform/postgresql-ha-images" "sha256:bbc6fec4e7e96c3a957890ba91d0a25bb7220f3a648c8132bfad131344c3100f"
sync_image "platform/postgresql-ha-images" "sha256:2a64cead50effd06a857d6118a4ef7c03dfed625b5b0a669d3c8286405e29f0b"
sync_image "platform/postgresql-ha-images" "sha256:79d2359d8b775886c2ce0c5e080b741ab0be1c5d9afe100105fe6d25e609ffe8"

# grafana-operator-images
sync_image "platform/grafana-operator-images" "sha256:7cdb67766a8bd554bf27bb10033e4eaa28f4ec9eb6d3ec0264fcee90cfa38345"
sync_image "platform/grafana-operator-images" "sha256:34d291799bd34a4176546774ccb43bbf508dc44afc333cdb0699cc0808192311"

# configmap-reload (used by splunk patches)
sync_image "platform/configmap-reload" "sha256:0000000000000000000000000000000000000000000000000000000000000000"  # tag-based, see note below

# ubuntu (used by node-exporter init container)
sync_image "platform/ubuntu" "sha256:0000000000000000000000000000000000000000000000000000000000000000"  # tag-based

# --------------------------------------------------------------------------
# Done
# --------------------------------------------------------------------------
echo ""
echo "======================================================"
echo "  All images synced to ${TEST_HARBOR}/oss/"
echo "======================================================"
echo ""
echo "Now update the repo: change all 'platform/' to 'oss/' in newName fields"
echo "The digests are already correct — same images = same sha256"
