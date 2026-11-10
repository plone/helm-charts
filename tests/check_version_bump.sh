#!/bin/bash
# Fail when the chart changed since BASE, but its version didn't increase.
# Run by make check-version, in CI for the pull requests to main: merging to
# main publishes the version of Chart.yaml, and skips a version that is
# published already, so a change without a new version would never be
# released.
#
# The unit tests and the CI scenarios aren't part of the release, so changing
# only them needs no new version.
set -euo pipefail

base=${1:?usage: check_version_bump.sh <base ref>}
chart=charts/plone

changed=$(git diff --name-only "$base"...HEAD -- "$chart" ":!$chart/tests" ":!$chart/ci")
if [ -z "$changed" ]; then
    echo "The chart didn't change since $base."
    exit 0
fi

version() {
    sed -n 's/^version: *"\{0,1\}\([^"]*\)"\{0,1\} *$/\1/p'
}
old=$(git show "$base:$chart/Chart.yaml" | version)
new=$(version < "$chart/Chart.yaml")
highest=$(printf '%s\n%s\n' "$old" "$new" | sort -V | tail -1)

echo "The chart changed since $base: version $old there, $new here."
if [ "$new" = "$old" ] || [ "$highest" != "$new" ]; then
    echo "Increase version in $chart/Chart.yaml, see CONTRIBUTING.md." >&2
    echo "Changed files:" >&2
    echo "$changed" >&2
    exit 1
fi
