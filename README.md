# Plone Helm chart

![test](https://github.com/plone/helm-charts/actions/workflows/test.yml/badge.svg)

The [`plone`](charts/plone) Helm chart installs [Plone 6](https://plone.org) on Kubernetes.
A single chart covers the common ways to run Plone, selected with a few values:

* **User interface:** the [Volto](https://6.docs.plone.org/volto/) frontend (default), or the Classic UI rendered by the backend
* **Storage:** RelStorage on PostgreSQL (default), or a ZEO server
* **Database:** a PostgreSQL cluster managed by [CloudNativePG](https://cloudnative-pg.io) (default), or an external PostgreSQL server
* **Cache:** an optional [Varnish](https://varnish-cache.org) cache in front of the site
* **Routing:** a [Gateway API](https://gateway-api.sigs.k8s.io) HTTPRoute (default), Ingress resources for ingress-nginx, or none

The default installs Plone 6 with Volto, PostgreSQL, and Gateway API.

Even if you do not want to use Helm for your setup, `helm template` might give you some ideas on how to deploy Plone on Kubernetes.

## Contents

* [Components](#components)
* [Quick start](#quick-start)
* [Scenarios](#scenarios)
* [Prerequisites](#prerequisites)
* [Configuration](#configuration)
* [Migrating from the previous charts](#migrating-from-the-previous-charts)
* [Development](#development)

## Components

Depending on the values, the chart installs:

| Component | Installed when | Documentation |
|---|---|---|
| Plone backend | always | [Backend](docs/components/backend.md), [Site](docs/components/site.md) |
| Volto frontend | `frontend.enabled` (default) | [Frontend](docs/components/frontend.md) |
| PostgreSQL cluster (CloudNativePG) | `postgresql.enabled` (default) | [Storage](docs/components/storage.md#relstorage-and-postgresql) |
| ZEO server | `storage.type: zeo` | [Storage](docs/components/storage.md#zeo) |
| Varnish | `varnish.enabled` | [Varnish](docs/components/varnish.md) |
| Pack job | `pack.enabled` (default) | [Storage](docs/components/storage.md#packing) |
| Routing | `routing.type` other than `none` | [Routing](docs/components/routing.md) |

## Quick start

[Helm](https://helm.sh) must be installed to use the chart.
Please refer to Helm's [documentation](https://helm.sh/docs) to get started.

1. Install the CloudNativePG operator, see [CloudNativePG operator](docs/prerequisites/cloudnativepg.md):

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

3. Install Plone.

   If your cluster has a Gateway API implementation and a Gateway, see [Gateway API](#gateway-api), attach the site to it:

   ```shell
   helm install plone plone/plone --namespace plone --create-namespace \
       --set routing.hostname=plone.example.com \
       --set routing.gateway.name=<gateway> \
       --set routing.gateway.namespace=<gateway-namespace>
   ```

   To try Plone without routing, install it with `routing.type` set to `none`:

   ```shell
   helm install plone plone/plone --namespace plone --create-namespace \
       --set routing.type=none
   kubectl port-forward --namespace plone service/plone-frontend 3000:3000
   ```

   and open http://localhost:3000.

A Job creates the Plone site after the install, which takes a few minutes, and `helm install` waits for it.
Follow it with `kubectl logs --namespace plone plone-backend-0 --follow`.

Then [change the password of the `admin` user](docs/components/site.md#admin-user).

## Scenarios

Each scenario is a set of values, described in its own page in the [`docs/scenarios`](docs/scenarios) directory.
Put the values in a file, and install the chart with `--values <file>`.
The scenarios can be combined: for example, add `--set varnish.enabled=true` to any of them, or replace the Gateway API routing with ingress-nginx.
The chart fails with an explanation when the values don't make sense together.

| Scenario | UI | Storage | Database or server | Routing |
|---|---|---|---|---|
| [Volto with PostgreSQL](docs/scenarios/volto-postgresql.md) (default) | Volto | RelStorage | CloudNativePG | Gateway API |
| [Volto with PostgreSQL and Varnish](docs/scenarios/volto-postgresql-varnish.md) | Volto | RelStorage | CloudNativePG | Gateway API |
| [Volto with ZEO](docs/scenarios/volto-zeo.md) | Volto | ZEO | ZEO server of the chart | Gateway API |
| [Classic UI with PostgreSQL](docs/scenarios/classic-postgresql.md) | Classic | RelStorage | CloudNativePG | Gateway API |
| [Classic UI with ZEO](docs/scenarios/classic-zeo.md) | Classic | ZEO | ZEO server of the chart | Gateway API |
| [External PostgreSQL](docs/scenarios/external-postgresql.md) | any | RelStorage | your PostgreSQL server | any |
| [External ZEO server](docs/scenarios/external-zeo.md) | any | ZEO | your ZEO server | any |
| [ingress-nginx routing](docs/scenarios/ingress-nginx.md) | any | any | any | ingress-nginx |
| [No routing](docs/scenarios/no-routing.md) | any | any | any | your own |

The [`charts/plone/ci`](charts/plone/ci) directory has the values of the scenarios tested on every change of the chart.

## Prerequisites

* Kubernetes 1.29 or later
* Helm 3.8 or later, for the OCI registry of the `varnish-cache` chart
* For the PostgreSQL scenarios with `postgresql.enabled`: the [CloudNativePG operator](docs/prerequisites/cloudnativepg.md)
* For `routing.type: gateway`: a [Gateway API](#gateway-api) implementation, and a Gateway
* For `routing.type: ingress-nginx`: the [ingress-nginx](#ingress-nginx) controller

### Gateway API

With `routing.type: gateway`, the chart only creates an HTTPRoute, attached to an existing Gateway with `routing.gateway.name` and `routing.gateway.namespace`, see [Routing](docs/components/routing.md#gateway-api-routing).
Installing the Gateway API CRDs, an implementation, and the Gateway is outside the scope of this chart: see the [Gateway API guides](https://gateway-api.sigs.k8s.io/guides/) and the documentation of your implementation.
Many implementations install the Gateway API CRDs themselves.
To try the chart on [Rancher Desktop or k3s with Traefik](docs/prerequisites/rancher-desktop.md), enable the Gateway API provider of Traefik first.

Unlike Ingress, which has a default IngressClass, Gateway API has no default Gateway in its standard channel: each HTTPRoute names the Gateways it attaches to, so set `routing.gateway.name` to the Gateway of your cluster.

The HTTPRoute only uses features of the Gateway API standard channel (`URLRewrite` with `ReplacePrefixMatch`), so it works with any conformant implementation, such as [Envoy Gateway](https://gateway.envoyproxy.io), [Traefik](https://doc.traefik.io/traefik/routing/providers/kubernetes-gateway/), [Istio](https://istio.io/latest/docs/tasks/traffic-management/ingress/gateway-api/), [Cilium](https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/gateway-api/), or [NGINX Gateway Fabric](https://docs.nginx.com/nginx-gateway-fabric/).
See the [list of implementations](https://gateway-api.sigs.k8s.io/implementations/).

### ingress-nginx

With `routing.type: ingress-nginx`, the chart creates Ingress resources for the [ingress-nginx](https://kubernetes.github.io/ingress-nginx/) controller, which must be installed in the cluster.
The ingress-nginx project was retired in March 2026, so this routing type is meant for clusters that still run it.
The NGINX Ingress Controller by F5 is a different product with different annotations, and isn't supported by this routing type.

## Configuration

All values are documented in [`charts/plone/values.yaml`](charts/plone/values.yaml).
The [`docs/components`](docs/components) directory explains the main ones, per component:

* [Site](docs/components/site.md): the Plone site created on the first start, and the `admin` user
* [Storage](docs/components/storage.md): RelStorage on PostgreSQL with CloudNativePG, ZEO, and packing
* [Backend](docs/components/backend.md): the `plone-backend` image, its pods, and environment variables
* [Frontend](docs/components/frontend.md): the Volto frontend, or the Classic UI without it
* [Varnish](docs/components/varnish.md): the optional cache in front of the site, and its VCL
* [Routing](docs/components/routing.md): Gateway API, ingress-nginx, and the Zope virtual host paths
* [Replicas and high availability](docs/components/high-availability.md): running more pods of each component

## Migrating from the previous charts

This chart replaces the charts that were previously in this repository.
They map to the following values:

| Previous chart | Values |
|---|---|
| `plone6-volto-pg` | defaults |
| `plone6-volto-pg-varnish` (formerly `plone6-volto-pg-nginx-varnish`) | `varnish.enabled: true` |
| `plone6-volto-zeo`, and the previous `plone` chart | `storage.type: zeo`, `postgresql.enabled: false` |
| `plone6-classic-pg` | `frontend.enabled: false` |
| `plone6-classic-nodb` | `frontend.enabled: false`, `postgresql.enabled: false`, and `storage.relstorage` pointing to your database |
| `backend`, `frontend`, `zeoserver`, `nginx`, `varnish`, `postgresql` subcharts | not needed anymore, they are part of this chart or replaced by community charts |

The resource names and values have changed, so install this chart as a new release and move the data, rather than upgrading a release of a previous chart.
The Traefik IngressRoute of `plone6-volto-pg` is replaced by the Gateway API routing, which Traefik supports.

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
