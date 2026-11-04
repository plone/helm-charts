# Plone Helm Charts

![test](https://github.com/plone/helm-charts/actions/workflows/test.yml/badge.svg)

A Helm chart to run [Plone 6](https://plone.org) on Kubernetes.
If you want to run Plone 6 on Kubernetes, this repository is a good starting point.

The [`plone`](charts/plone) chart covers the common ways to run Plone, selected with a few values:

* the Volto frontend, or the Classic UI
* RelStorage on PostgreSQL, with a database managed by [CloudNativePG](https://cloudnative-pg.io) or an external one, or a ZEO server
* an optional Varnish cache
* routing with [Gateway API](https://gateway-api.sigs.k8s.io), or with ingress-nginx

By default, it installs Plone 6 with Volto, PostgreSQL, and Gateway API.
See the [chart documentation](charts/plone/README.md) for the scenarios, their prerequisites, and how to set them up.

Even if you do not want to use Helm for your setup, `helm template` might give you some ideas on how to deploy Plone on Kubernetes.

## Usage

[Helm](https://helm.sh) must be installed to use the chart.
Please refer to Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

```shell
helm repo add plone https://plone.github.io/helm-charts
```

If you had already added this repo earlier, run `helm repo update` to retrieve the latest versions of the packages.
Then, run `helm search repo plone` to see the charts.

## Quick start

The default scenario needs the CloudNativePG operator in your cluster:

```shell
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm upgrade --install cnpg cnpg/cloudnative-pg \
    --namespace cnpg-system --create-namespace --wait
```

To try Plone without setting up routing, install it with `routing.type` set to `none`, and forward a local port to the frontend:

```shell
helm install plone plone/plone --namespace plone --create-namespace \
    --set routing.type=none
kubectl port-forward --namespace plone service/plone-frontend 3000:3000
```

The backend creates the Plone site on its first start, which takes a few minutes.
Then open http://localhost:3000.

See the [chart documentation](charts/plone/README.md#quick-start) to expose the site with Gateway API or ingress-nginx.

## Development

The chart is in [`charts/plone`](charts/plone).
To install it from a checkout of this repository, add the repository of the CloudNativePG `cluster` chart, and fetch the dependencies:

```shell
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm dependency update ./charts/plone
helm install plone ./charts/plone --values ./charts/plone/ci/default-values.yaml
```

The [`ci`](charts/plone/ci) directory has a values file per tested scenario.
The GitHub Actions workflow lints and installs the chart with each of them, and [`test.sh`](test.sh) does the same in a local cluster.
