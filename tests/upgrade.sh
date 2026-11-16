#!/bin/bash
# Upgrade test, run by make test-upgrade: install the last published release of
# the chart, create content, upgrade the release to the chart of this checkout,
# then check the content, and run helm test.
#
# The published chart is installed with the values file of its own release, at
# the tag plone-<version>: the values of this checkout may have keys that its
# schema refuses.
#
# Settings, from the environment:
#   UPGRADE_FROM         version of the published chart to upgrade from; empty
#                        for the latest one
#   UPGRADE_VALUES       values file of the upgrade, as a path in this
#                        repository; the install of the published chart reads
#                        the same path at its release tag
#   UPGRADE_FROM_VALUES  values file of the install of the published chart,
#                        instead of the one at its release tag
#   UPGRADE_NAMESPACE    namespace of the release, deleted at the end
set -euo pipefail

repo=https://plone.github.io/helm-charts
sources=https://raw.githubusercontent.com/plone/helm-charts
chart=charts/plone
release=upgrade
namespace=${UPGRADE_NAMESPACE:-plone-upgrade}
values=${UPGRADE_VALUES:-$chart/ci/default-values.yaml}
values=${values#./}
from_values=${UPGRADE_FROM_VALUES:-}
tmp=$(mktemp -d)

cleanup() {
    rm -rf "$tmp"
    helm uninstall "$release" --namespace "$namespace" --wait > /dev/null 2>&1 || true
    kubectl delete namespace "$namespace" --ignore-not-found --wait=false
}
trap cleanup EXIT

# The version to upgrade from, resolved before the install, so that the values
# file comes from the same release as the chart.
from=${UPGRADE_FROM:-}
if [ -z "$from" ]; then
    from=$(helm show chart plone --repo "$repo" | sed -n 's/^version: *//p')
    if [ -z "$from" ]; then
        echo "Couldn't find the latest version of the chart plone in $repo." >&2
        exit 1
    fi
fi

if [ -z "$from_values" ]; then
    case "$values" in
        /*)
            echo "UPGRADE_VALUES must be a path in this repository, to read it at the tag plone-$from; set UPGRADE_FROM_VALUES for the install of $from." >&2
            exit 1 ;;
    esac
    from_values=$tmp/from-values.yaml
    url=$sources/plone-$from/$values
    if ! curl -fsSL "$url" -o "$from_values"; then
        echo "The release plone-$from has no $values ($url)." >&2
        echo "Set UPGRADE_FROM_VALUES to a values file for the chart $from." >&2
        exit 1
    fi
fi

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

echo "==> Install the published chart $from, with the values of ${UPGRADE_FROM_VALUES:-plone-$from/$values}"
helm install "$release" plone --repo "$repo" --version "$from" \
    --namespace "$namespace" --create-namespace \
    --values "$from_values" --wait --timeout 15m
helm list --namespace "$namespace"

echo "==> Create content"
content create

echo "==> Upgrade to the chart of this checkout, with the values of $values"
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

# What helm uninstall does to the database, as the documentation warns: the
# PostgreSQL Cluster is a resource of the release, and its volumes belong to
# it, so they are deleted with it.
echo "==> Uninstall, and check that the PostgreSQL volumes are deleted"
pvcs() {
    kubectl get pvc --namespace "$namespace" -l "cnpg.io/cluster=$release-postgresql" -o name
}
echo "Volumes before: $(pvcs | tr '\n' ' ')"
[ -n "$(pvcs)" ] || { echo "No PostgreSQL volume found before the uninstall" >&2; exit 1; }
helm uninstall "$release" --namespace "$namespace" --wait
for _ in $(seq 24); do
    [ -z "$(pvcs)" ] && break
    sleep 5
done
kubectl get cluster,pvc --namespace "$namespace"
if [ -n "$(pvcs)" ]; then
    echo "The PostgreSQL volumes remain after helm uninstall: update the warning of the documentation" >&2
    exit 1
fi
echo "helm uninstall deleted the PostgreSQL cluster and its volumes"
