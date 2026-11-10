# Contributing to the Plone Helm chart

Thank you for helping.
This repository follows the [Plone contributing guidelines](https://6.docs.plone.org/contributing/index.html).
To have a pull request merged, you need to sign the [Plone Contributor Agreement](https://plone.org/foundation/contributors-agreement).

Report security issues privately, as described in the [Plone security policy](https://plone.org/security/report), not in a public issue.

## The repository

* [`charts/plone`](charts/plone): the chart, with its values, templates, and the JSON schema of its values.
* [`charts/plone/tests`](charts/plone/tests): the unit tests of the templates, for [helm-unittest](https://github.com/helm-unittest/helm-unittest).
* [`charts/plone/ci`](charts/plone/ci): one values file per scenario that CI installs.
* [`tests`](tests): the scripts of the upgrade test, the external servers of the CI scenarios, and the check of the values reference.
* [`docs`](docs): the documentation, published at <https://plone.github.io/helm-charts/>.

## Check your change

The `Makefile` runs the same checks as CI.
These need [Helm](https://helm.sh) and Docker:

```shell
make test           # unit tests, and the manifests of each scenario against several Kubernetes versions
```

These need [chart-testing](https://github.com/helm/chart-testing), and a cluster such as one created with [kind](https://kind.sigs.k8s.io) as the current `kubectl` context:

```shell
make lint           # lint each scenario
make cluster-deps   # install CloudNativePG, the Gateway API CRDs, Traefik, ingress-nginx, and the external servers
make test-install   # install each scenario, and run helm test
make test-upgrade   # upgrade from the last published release
```

The documentation needs [uv](https://docs.astral.sh/uv/):

```shell
make docs           # build it, warnings are errors
make docs-vale      # check the style
make docs-values    # check that the values reference documents every value
```

## What a change includes

* Tests: a unit test for a new template branch or validation rule, and a CI scenario for a new combination of values that the documentation describes.
* Values: a comment in `values.yaml`, the type in `values.schema.json`, and a row in `docs/reference/values.md`.
* Documentation: the how-to guides and reference pages that the change affects.
* An entry in [`CHANGELOG.md`](CHANGELOG.md), under the unreleased version, with a link to the issue.
  Describe what changes for the people who install the chart.
  A change that needs action on upgrade goes under "Breaking changes", with the steps to take.

## Versions and releases

Each change to the chart that reaches `main` must change `version` in `charts/plone/Chart.yaml`: CI fails a pull request to `main` without it.
Until 1.0, a minor version can bring breaking changes, and a patch version doesn't.

Merging to `main` publishes the version of `Chart.yaml` to the Helm repository, if it isn't published yet.
To group several pull requests in one release, base each one on the previous one, and bump the version in the last one.
