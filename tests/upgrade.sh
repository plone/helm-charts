#!/bin/bash
# Upgrade test, run by make test-upgrade: install the last published release of
# the chart, create content, upgrade the release to the chart of this checkout,
# then check the content, and run helm test.
#
# Settings, from the environment:
#   UPGRADE_FROM       version of the published chart to upgrade from; empty
#                      for the latest one
#   UPGRADE_VALUES     values file of both installs
#   UPGRADE_NAMESPACE  namespace of the release, deleted at the end
set -euo pipefail

repo=https://plone.github.io/helm-charts
chart=charts/plone
release=upgrade
namespace=${UPGRADE_NAMESPACE:-plone-upgrade}
values=${UPGRADE_VALUES:-$chart/ci/default-values.yaml}
version_args=()
if [ -n "${UPGRADE_FROM:-}" ]; then
    version_args=(--version "$UPGRADE_FROM")
fi

cleanup() {
    helm uninstall "$release" --namespace "$namespace" --wait > /dev/null 2>&1 || true
    kubectl delete namespace "$namespace" --ignore-not-found --wait=false
}
trap cleanup EXIT

# The password of the admin user: the one of the Secret of the chart, or the
# password "admin" of the image, for the releases that didn't set it.
admin_password() {
    kubectl get secret "$release-admin" --namespace "$namespace" \
        -o jsonpath='{.data.password}' 2> /dev/null | base64 -d || true
}

# Run tests/upgrade_content.py in a ready backend pod.
content() {
    local pod password
    pod=$(kubectl get pod --namespace "$namespace" \
        -l "app.kubernetes.io/instance=$release,app.kubernetes.io/component=backend" \
        --field-selector=status.phase=Running -o name | head -1)
    password=$(admin_password)
    kubectl exec -i --namespace "$namespace" "$pod" -- \
        python - "$1" "${password:-admin}" < tests/upgrade_content.py
}

echo "==> Install the published chart ${UPGRADE_FROM:-(latest)}"
helm install "$release" plone --repo "$repo" "${version_args[@]}" \
    --namespace "$namespace" --create-namespace \
    --values "$values" --wait --timeout 15m
helm list --namespace "$namespace"

echo "==> Create content"
content create

echo "==> Upgrade to the chart of this checkout"
helm upgrade "$release" "$chart" --namespace "$namespace" \
    --values "$values" --wait --timeout 15m
helm list --namespace "$namespace"
# Up to 0.3.0, the backend was a StatefulSet, whose pod has the labels of the
# pods of the Deployment: wait until it is gone.
kubectl wait --for=delete "pod/$release-backend-0" --namespace "$namespace" --timeout=180s 2> /dev/null || true

echo "==> Check the content"
content check

echo "==> Run helm test"
helm test "$release" --namespace "$namespace" --logs
