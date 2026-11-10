#!/bin/bash
# Install test, run by make test-install: install the chart of this checkout once
# per CI scenario, charts/plone/ci/*-values.yaml, run helm test, and uninstall it.
#
# The namespace enforces the restricted Pod Security profile, so every pod of the
# chart must comply. helm test skips the ping test of the CloudNativePG cluster
# chart, whose pod runs as root to install psql: the restricted profile refuses
# it, and the checks of this chart already reach the database.
#
# Settings, from the environment:
#   CI_NAMESPACE  namespace of the releases, prepared by make cluster-deps
#   SCENARIOS     values files to install; all the CI scenarios by default
set -euo pipefail

chart=charts/plone
namespace=${CI_NAMESPACE:-plone-ci}
read -r -a scenarios <<< "${SCENARIOS:-$(echo "$chart"/ci/*-values.yaml)}"
release=""

# What a failed install leaves behind, for the log of CI.
debug() {
    echo "==> State of the namespace $namespace"
    kubectl get pods,jobs --namespace "$namespace" -o wide || true
    kubectl get events --namespace "$namespace" --sort-by=.lastTimestamp | tail -40 || true
    for pod in $(kubectl get pods --namespace "$namespace" -l "app.kubernetes.io/instance=$release" -o name 2> /dev/null); do
        echo "--- $pod"
        kubectl logs --namespace "$namespace" "$pod" --all-containers --tail=40 || true
    done
}

uninstall() {
    [ -n "$release" ] || return 0
    helm uninstall "$release" --namespace "$namespace" --wait > /dev/null 2>&1 || true
    # The volumes of the ZEO server, and the hooks that uninstall leaves.
    kubectl delete pvc,pod,configmap,job --namespace "$namespace" \
        -l "app.kubernetes.io/instance=$release" --ignore-not-found --wait=false > /dev/null
}

on_exit() {
    status=$?
    if [ "$status" -ne 0 ]; then
        echo "FAILED: $release"
        debug
    fi
    uninstall
    exit "$status"
}
trap on_exit EXIT

for values in "${scenarios[@]}"; do
    scenario=$(basename "$values" -values.yaml)
    release=ci-$scenario
    echo "==> $scenario: install $release"
    helm install "$release" "$chart" --namespace "$namespace" \
        --values "$values" --wait --timeout 15m
    echo "==> $scenario: helm test"
    helm test "$release" --namespace "$namespace" --logs --timeout 10m \
        --filter "!name=$release-postgresql-ping-test"
    echo "==> $scenario: uninstall"
    uninstall
    release=""
done
echo "==> ${#scenarios[@]} scenarios installed and tested"
