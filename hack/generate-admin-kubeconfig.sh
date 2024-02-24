#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

hostname="$(cat hack/kind-values.yaml | yq '.externalHostname')"

cat << EOF > kcp.kubeconfig
apiVersion: v1
kind: Config
clusters:
  - cluster:
      insecure-skip-tls-verify: true
      server: "https://$hostname:6443/clusters/root"
    name: kind-kcp
contexts:
  - context:
      cluster: kind-kcp
      user: kind-kcp
    name: kind-kcp
current-context: kind-kcp
users:
  - name: kind-kcp
    user:
      token: admin-token
EOF

echo "Kubeconfig file created at kcp.kubeconfig"
echo ""
echo "export KUBECONFIG=kcp.kubeconfig"
echo ""
