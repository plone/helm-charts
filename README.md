# Plone Helm chart

![test](https://github.com/plone/helm-charts/actions/workflows/test.yml/badge.svg)

The [`plone`](charts/plone) Helm chart installs [Plone 6](https://6.docs.plone.org/) on Kubernetes.
A single chart covers the common ways to run Plone: with the [Volto](https://6.docs.plone.org/volto/) frontend or the Classic UI, on PostgreSQL or ZEO, with or without a Varnish cache, and with Gateway API or ingress-nginx routing.

The default installs Plone 6 with Volto, PostgreSQL, and Gateway API.

## Documentation

The documentation is in [`docs`](docs/index.md), organized by the [Diátaxis](https://diataxis.fr) framework:

* [Tutorial](docs/tutorials/install-plone-on-rancher-desktop.md): install Plone on Rancher Desktop, step by step.
* [How-to guides](docs/how-to/index.md): install each scenario, attach the site to a Gateway, serve it over HTTPS, cache it with Varnish, and more.
* [Reference](docs/reference/index.md): the values, the components, and the resources of the chart.
* [Explanation](docs/explanation/index.md): the architecture, the storage choices, and the routing.

## Quick start

[Helm](https://helm.sh) 3.8 or later, and Kubernetes 1.29 or later, are required.

1. Install the [CloudNativePG operator](docs/how-to/install-cloudnativepg.md), which runs the PostgreSQL cluster of the default scenario:

   ```shell
   helm repo add cnpg https://cloudnative-pg.github.io/charts
   helm upgrade --install cnpg cnpg/cloudnative-pg \
       --namespace cnpg-system --create-namespace --wait
   ```

2. Add the Plone Helm repository:

   ```shell
   helm repo add plone https://plone.github.io/helm-charts
   helm repo update
   ```

3. Install Plone without routing, and open it with a port forward:

   ```shell
   helm install plone plone/plone --namespace plone --create-namespace \
       --set routing.type=none
   kubectl port-forward --namespace plone service/plone-frontend 3000:3000
   ```

   A Job creates the Plone site after the install, which takes a few minutes, and `helm install` waits for it.
   Then open http://localhost:3000.

Then [change the password of the `admin` user](docs/how-to/change-admin-password.md).
To serve the site through a route instead, see [Gateway API](#gateway-api), or follow the [tutorial](docs/tutorials/install-plone-on-rancher-desktop.md).

## Gateway API

With the default `routing.type: gateway`, the chart creates an HTTPRoute, attached to a Gateway that already exists in your cluster, set with `routing.gateway.name`.
The chart doesn't install the Gateway API CRDs, an implementation, or the Gateway.
See [How to attach the site to a Gateway](docs/how-to/attach-to-gateway.md), and [About Gateway API](docs/explanation/gateway-api.md).

## ingress-nginx

With `routing.type: ingress-nginx`, the chart creates Ingress resources for the ingress-nginx controller.
The ingress-nginx project was retired in March 2026, so this routing type is meant for clusters that still run it.
See [How to route the site with ingress-nginx](docs/how-to/use-ingress-nginx.md).

## Scenarios

The [how-to guides](docs/how-to/index.md#choose-an-installation) describe each combination of values that the chart supports, such as the Classic UI with ZEO, or an external PostgreSQL server.
The scenarios can be combined, and the chart fails with an explanation when the values don't make sense together.

All the values are described in the [values reference](docs/reference/values.md), and the default values are in [`charts/plone/values.yaml`](charts/plone/values.yaml).

## Migrating from the previous charts

This chart replaces the charts that were previously in this repository.
See [How to migrate from the previous charts](docs/how-to/migrate-from-previous-charts.md).

## Development

The chart is in [`charts/plone`](charts/plone).
To install it from a checkout of this repository, add the repository of the CloudNativePG `cluster` chart, and fetch the dependencies:

```shell
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm dependency update ./charts/plone
helm install plone ./charts/plone --values ./charts/plone/ci/default-values.yaml
```

The [`charts/plone/ci`](charts/plone/ci) directory has a values file per tested scenario.
The GitHub Actions workflow lints and installs the chart with each of them, and [`test.sh`](test.sh) does the same in a local cluster.
