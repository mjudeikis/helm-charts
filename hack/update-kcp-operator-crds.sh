#!/usr/bin/env bash

set -euo pipefail
cd $(dirname $0)/..

cd charts/kcp-operator/
version="$(yq '.appVersion' Chart.yaml)"
crdFileCore=templates/crds.yaml
crdFileCompiled=templates/crds-compiled.yaml

# HACK: The kcp-operator CRDs are huge, mostly because of the doc strings generated
# The kcp-operator CRDs are huge, mostly because of the doc strings generated
# from the Go types. Two Helm limits make shipping them verbatim impossible:
#
#   * since Helm 3.17.3 no single chart file may exceed 5 MiB
#   * the release Secret holds both the chart source and the rendered manifest,
#     gzipped, and has to stay below etcd's 1 MiB object limit
#
# Dropping the descriptions cuts the CRDs to roughly a third of their size,
# which fits both. The trade-off is that "kubectl explain" no longer documents
# the kcp-operator types.
#
# Only string-valued "description" keys are dropped, so a future API field
# actually named "description" (a map in the schema) is left alone.
stripDescriptions='del(.. | select(has("description") and (.description | tag == "!!str")).description)'

set -x

echo "{{- if .Values.crds.create }}" > "$crdFileCore"
kubectl kustomize "https://github.com/kcp-dev/kcp-operator/config/crd?ref=$version" | yq "$stripDescriptions" >> "$crdFileCore"
echo "{{- end }}" >> "$crdFileCore"

echo "{{- if .Values.crds.create }}" > "$crdFileCompiled"
kubectl kustomize "https://github.com/kcp-dev/kcp-operator/config/crd/deploy?ref=$version" | yq "$stripDescriptions" >> "$crdFileCompiled"
echo "{{- end }}" >> "$crdFileCompiled"
