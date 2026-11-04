# Plone Helm chart

![test](https://github.com/plone/helm-charts/actions/workflows/test.yml/badge.svg)

The [`plone`](charts/plone) Helm chart installs [Plone 6](https://plone.org) on Kubernetes.
A single chart covers the common ways to run Plone, selected with a few values:

* **User interface:** the [Volto](https://6.docs.plone.org/volto/) frontend (default), or the Classic UI rendered by the backend
* **Storage:** RelStorage on PostgreSQL (default), or a ZEO server
* **Database:** a PostgreSQL cluster managed by [CloudNativePG](https://cloudnative-pg.io) (default), or an external PostgreSQL server
* **Cache:** an optional [Varnish](https://varnish-cache.org) cache in front of the backend
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

Depending on the values, the chart creates:

| Component | Resources | Created when |
|---|---|---|
| Backend | StatefulSet `<release>-backend`, services `<release>-backend` and `<release>-backend-director` | always |
| Frontend | Deployment and service `<release>-frontend` | `frontend.enabled` (default) |
| PostgreSQL | CloudNativePG cluster `<release>-postgresql` | `postgresql.enabled` (default) |
| ZEO server | StatefulSet and service `<release>-zeo` | `storage.type: zeo`, without `storage.zeo.address` |
| Varnish | Deployment and service `<release>-varnish` | `varnish.enabled` |
| Pack job | CronJob `<release>-pack` | `pack.enabled` (default) |
| Routing | HTTPRoute, or Ingress resources | `routing.type` other than `none` |

The PostgreSQL cluster and Varnish are installed with community charts:
the [`cluster` chart](https://github.com/cloudnative-pg/charts/tree/main/charts/cluster) of CloudNativePG, and the [`varnish-cache` chart](https://github.com/varnish/helm-varnish-cache) of Varnish Software.

The backend runs the [`plone-backend` image](https://6.docs.plone.org/install/containers/images/backend.html), configured with its environment variables.
On its first start, it creates the Plone site: a Volto site with the frontend, a Classic UI site without it.

## Quick start

[Helm](https://helm.sh) must be installed to use the chart.
Please refer to Helm's [documentation](https://helm.sh/docs) to get started.

1. Install the CloudNativePG operator, see [CloudNativePG operator](#cloudnativepg-operator):

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
       --set routing.gateway.parentRefs[0].name=<gateway> \
       --set routing.gateway.parentRefs[0].namespace=<gateway-namespace>
   ```

   To try Plone without routing, install it with `routing.type` set to `none`:

   ```shell
   helm install plone plone/plone --namespace plone --create-namespace \
       --set routing.type=none
   kubectl port-forward --namespace plone service/plone-frontend 3000:3000
   ```

   and open http://localhost:3000.

The backend creates the Plone site on its first start, which takes a few minutes.
Follow it with `kubectl logs --namespace plone plone-backend-0 --follow`.

Then [change the password of the `admin` user](#admin-user).

## Scenarios

Each scenario is a set of values, described in its own page in the [`scenarios`](scenarios) directory.
Put the values in a file, and install the chart with `--values <file>`.
The scenarios can be combined: for example, add `varnish.enabled: true` to any of them, or replace the Gateway API routing with ingress-nginx.
The chart fails with an explanation when the values don't make sense together.

| Scenario | UI | Storage | Database or server | Routing |
|---|---|---|---|---|
| [Volto with PostgreSQL](scenarios/volto-postgresql.md) (default) | Volto | RelStorage | CloudNativePG | Gateway API |
| [Volto with PostgreSQL and Varnish](scenarios/volto-postgresql-varnish.md) | Volto | RelStorage | CloudNativePG | Gateway API |
| [Volto with ZEO](scenarios/volto-zeo.md) | Volto | ZEO | ZEO server of the chart | Gateway API |
| [Classic UI with PostgreSQL](scenarios/classic-postgresql.md) | Classic | RelStorage | CloudNativePG | Gateway API |
| [Classic UI with ZEO](scenarios/classic-zeo.md) | Classic | ZEO | ZEO server of the chart | Gateway API |
| [External PostgreSQL](scenarios/external-postgresql.md) | any | RelStorage | your PostgreSQL server | any |
| [External ZEO server](scenarios/external-zeo.md) | any | ZEO | your ZEO server | any |
| [ingress-nginx routing](scenarios/ingress-nginx.md) | any | any | any | ingress-nginx |
| [No routing](scenarios/no-routing.md) | any | any | any | your own |

The [`charts/plone/ci`](charts/plone/ci) directory has the values of the scenarios tested on every change of the chart.

## Prerequisites

* Kubernetes 1.29 or later
* Helm 3.8 or later, for the OCI registry of the `varnish-cache` chart
* For the PostgreSQL scenarios with `postgresql.enabled`: the [CloudNativePG operator](#cloudnativepg-operator)
* For `routing.type: gateway`: the [Gateway API CRDs, an implementation, and a Gateway](#gateway-api)
* For `routing.type: ingress-nginx`: the [ingress-nginx controller](#ingress-nginx)

### CloudNativePG operator

The PostgreSQL cluster is run by the CloudNativePG operator, a CNCF project, which takes care of the database pods, volumes, credentials, failover, and backups.
Install it once per Kubernetes cluster, before you install the chart.
It needs permissions to create cluster-wide resources (CustomResourceDefinitions and ClusterRoles), usually as a cluster administrator.

With Helm:

```shell
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm upgrade --install cnpg cnpg/cloudnative-pg \
    --namespace cnpg-system --create-namespace --wait
```

Or with `kubectl`, from the release manifest:

```shell
kubectl apply --server-side -f \
    https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.30/releases/cnpg-1.30.1.yaml
kubectl rollout status deployment -n cnpg-system cnpg-controller-manager
```

Check that the operator is installed with:

```shell
kubectl get crd clusters.postgresql.cnpg.io
```

To upgrade the operator later, run the same commands with a newer version.
See the [CloudNativePG installation documentation](https://cloudnative-pg.io/documentation/current/installation_upgrade/) for other methods, such as OLM, and for upgrade notes.

### Gateway API

With `routing.type: gateway`, the chart creates an HTTPRoute attached to an existing Gateway.
It only uses features of the Gateway API standard channel (`URLRewrite` with `ReplacePrefixMatch`), so it works with any conformant implementation, such as [Envoy Gateway](https://gateway.envoyproxy.io), [Traefik](https://doc.traefik.io/traefik/routing/providers/kubernetes-gateway/), [Istio](https://istio.io/latest/docs/tasks/traffic-management/ingress/gateway-api/), [Cilium](https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/gateway-api/), or [NGINX Gateway Fabric](https://docs.nginx.com/nginx-gateway-fabric/).
See the [list of implementations](https://gateway-api.sigs.k8s.io/implementations/).

#### Install the Gateway API CRDs

Many implementations install the Gateway API CRDs themselves, so check their documentation first.
Otherwise, install the standard channel CRDs with:

```shell
kubectl apply --server-side -f \
    https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.7.0/standard-install.yaml
```

Check that they are installed with:

```shell
kubectl get crd httproutes.gateway.networking.k8s.io
```

#### Install an implementation

For example, to install Envoy Gateway with Helm:

```shell
helm install eg oci://docker.io/envoyproxy/gateway-helm \
    --version v1.9.3 \
    --namespace envoy-gateway-system --create-namespace --wait
```

Then create its GatewayClass:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: eg
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
```

Follow the documentation of your implementation for production settings.

#### Create a Gateway

The Gateway is usually shared by several applications and managed by the cluster administrator, so this chart doesn't create it.
For example, a Gateway named `plone` with an HTTP listener, and an HTTPS listener with a certificate in the `plone-tls` secret:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: plone
  namespace: gateway-system
spec:
  gatewayClassName: eg
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: All
    - name: https
      protocol: HTTPS
      port: 443
      hostname: plone.example.com
      tls:
        certificateRefs:
          - name: plone-tls
      allowedRoutes:
        namespaces:
          from: All
```

[cert-manager](https://cert-manager.io/docs/usage/gateway/) can issue the certificate for the HTTPS listener.

### ingress-nginx

With `routing.type: ingress-nginx`, the chart creates Ingress resources for the [ingress-nginx](https://kubernetes.github.io/ingress-nginx/) controller, which must be installed in the cluster.
The ingress-nginx project was retired in March 2026, so this routing type is meant for clusters that still run it.
The NGINX Ingress Controller by F5 is a different product with different annotations, and isn't supported by this routing type.

## Configuration

All values are documented in [`charts/plone/values.yaml`](charts/plone/values.yaml).
This section explains the main ones.

### Site

```yaml
site:
  id: Plone
  create: true
  profiles: ""
  defaultLanguage: ""
```

With `site.create`, the backend creates a Plone site with the id `site.id` on its start, if it doesn't exist yet.
The type of the site follows `frontend.enabled`: a Volto site with the frontend, a Classic UI site without it.
`site.profiles` lists add-on profiles to apply when creating the site, comma separated, and `site.defaultLanguage` sets its language, such as `en` or `pt-br`.
These values only apply when the site is created, and changing them later has no effect on an existing site.

To create the site yourself, set `site.create` to `false`, and use `kubectl port-forward` to the backend to open the Zope root.

The site id is also used in the virtual host paths of the routing, and in the API URL of the frontend.

#### Admin user

The `plone-backend` image comes with a Zope `admin` user with the password `admin`.
Change it before exposing the site:

1. Forward a local port to the backend:

   ```shell
   kubectl port-forward --namespace <namespace> service/<release>-backend 8080:8080
   ```

2. Open http://localhost:8080/acl_users/manage_main, log in as `admin`, select the `admin` user, and change its password.

### Storage

`storage.type` selects how Plone stores its database:

* `relstorage` (default): RelStorage on PostgreSQL. Objects and blobs are stored in the database, and each backend pod only keeps a cache.
* `zeo`: a ZEO server. The backend pods are its clients.

#### RelStorage and PostgreSQL

With `postgresql.enabled` (default), the chart creates a PostgreSQL cluster with the CloudNativePG `cluster` chart, named `<release>-postgresql`, with:

* one instance, with an 8Gi volume created by the operator
* a `plone` database, owned by the `plone` user
* a `<release>-postgresql-app` secret with the generated credentials of the `plone` user
* a `<release>-postgresql-rw` service that always points to the primary instance

The backend connects to `<release>-postgresql-rw` with the credentials from `<release>-postgresql-app`.
You don't need to create a PersistentVolumeClaim or a credentials secret.

All options of the `cluster` chart can be set under the `postgresql` key.
For example, to run three instances with automatic failover:

```yaml
postgresql:
  cluster:
    instances: 3
    enablePDB: true
```

See the [`cluster` chart documentation](https://github.com/cloudnative-pg/charts/tree/main/charts/cluster) for backups, monitoring, connection pooling, and recovery.
To connect through a connection pooler, set `storage.relstorage.host` to the service of the pooler.

Other RelStorage options:

```yaml
storage:
  relstorage:
    # Keep the history of the objects, needed for undo.
    keepHistory: true
    # Size of the blob cache of each backend pod.
    blobCacheSize: 100mb
```

To use an external PostgreSQL server, see [External PostgreSQL](scenarios/external-postgresql.md).

#### ZEO

With `storage.type: zeo` and no `storage.zeo.address`, the chart deploys a ZEO server with the [`plone-zeo` image](https://6.docs.plone.org/install/containers/images/zeo.html), storing its data in a 5Gi persistent volume:

```yaml
storage:
  type: zeo
  zeo:
    clientCacheSize: 128MB
    server:
      persistence:
        enabled: true
        storageClass: ""
        size: 5Gi
postgresql:
  enabled: false
```

Set `postgresql.enabled` to `false` with ZEO, so that the chart doesn't create a PostgreSQL cluster that Plone wouldn't use.
The volume is created from a volume claim template of the ZEO StatefulSet, so it's kept when you uninstall the chart.

To use an external ZEO server, see [External ZEO server](scenarios/external-zeo.md).

### Packing

The `<release>-pack` CronJob packs the database regularly, removing old object revisions and unused objects, with `zodbpack` for RelStorage and `zeopack` for ZEO:

```yaml
pack:
  enabled: true
  schedule: "45 9 * * *"
  # Keep the history of the last days. 0 packs everything.
  days: 0
```

### Backend

```yaml
backend:
  replicas: 2
  zodbCacheSize: 50000
  env: []
  resources:
    requests:
      cpu: 100m
      memory: 300Mi
```

`backend.env` adds environment variables to the backend, see the [`plone-backend` image documentation](https://6.docs.plone.org/install/containers/images/backend.html) for the supported ones.
The image tag defaults to the chart `appVersion`.
To run your own image with add-ons, set `backend.image.repository` and `backend.image.tag`.

The backend is a StatefulSet, with the headless `<release>-backend-director` service that StatefulSets require, so that each pod has a stable name.
Its startup probe allows 10 minutes for the first start, during which the site is created.

### Frontend

```yaml
frontend:
  enabled: true
  image:
    repository: docker.io/plone/plone-frontend
    tag: "19.6.1"
  replicas: 2
  env: []
```

Set `frontend.enabled` to `false` for the Classic UI.
To run your own Volto project, set `frontend.image.repository` and `frontend.image.tag`.
The frontend calls the backend directly for server-side rendering, through `RAZZLE_INTERNAL_API_PATH`, and the browsers call it through the `/++api++` route.

### Varnish

With `varnish.enabled`, the chart installs Varnish with the `varnish-cache` chart, and routes the backend requests through it.
The default configuration runs two Varnish replicas, as a Deployment with a PodDisruptionBudget, behind a `ClusterIP` service on port 6081.

The VCL is set in `varnish.server.vclConfig`.
The default VCL has a single backend, the `<release>-backend` Service:

```yaml
varnish:
  enabled: true
  server:
    replicas: 2
    vclConfig: |
      vcl 4.1;

      backend default {
          .host = "{{ .Release.Name }}-backend";
          .port = "8080";
      }
```

The Service balances the connections of Varnish between the backend pods, and only sends them to the pods that are ready, so the VCL doesn't depend on the number of backend pods.
Kubernetes balances per connection, not per request, but Varnish keeps a pool of connections to the backend, which spreads the load between the pods.

To customize the caching, replace `varnish.server.vclConfig` with your own VCL, keeping the backend.
It's rendered as a template by the `varnish-cache` chart, with its own values, so it can use `.Release.Name`, but not the values of this chart.
If you set `fullnameOverride`, set the backend host to `<fullnameOverride>-backend`.
The `varnish-cache` chart restarts the Varnish pods when the VCL changes.

All the options of the `varnish-cache` chart can be set under `varnish`, see its [documentation](https://github.com/varnish/helm-varnish-cache).

### Routing

The routing sends the requests to the frontend and the backend:

* With Volto:
  * `/++api++` goes to the backend (through Varnish if enabled), rewritten for the Zope virtual host monster, for example `/++api++/news` becomes `/VirtualHostBase/https/plone.example.com:443/Plone/++api++/VirtualHostRoot/news`, so that the backend generates URLs with the public hostname.
  * Everything else goes to the frontend. The frontend itself sends the caching headers of its static assets, with a one year `max-age` for `/static`.
* With the Classic UI, everything goes to the backend (through Varnish if enabled), rewritten to `/VirtualHostBase/https/plone.example.com:443/Plone/VirtualHostRoot/...`.

The options shared by both routing types are:

```yaml
routing:
  # gateway, ingress-nginx, or none
  type: gateway
  # Public hostname of the site.
  hostname: plone.example.com
  # Whether clients use HTTPS, and on which port. The port defaults to 443
  # with HTTPS and 80 without.
  https: true
  port: ""
```

TLS itself is terminated by the Gateway or the ingress controller, not by Plone.
`routing.https` and `routing.port` only tell Plone which scheme and port the clients use, for the URLs it generates.

#### Gateway API routing

```yaml
routing:
  type: gateway
  gateway:
    parentRefs:
      - name: plone
        namespace: gateway-system
        sectionName: https
    annotations: {}
```

`routing.gateway.parentRefs` lists the Gateways, and optionally their listeners, that the HTTPRoute attaches to.
Check that the Gateway accepted the route with:

```shell
kubectl describe httproute --namespace <namespace> <release>
```

#### ingress-nginx routing

```yaml
routing:
  type: ingress-nginx
  ingressNginx:
    className: nginx
    annotations: {}
    tls: []
```

With Volto, the chart creates:

* `<release>-api`: the `/++api++` route, with the `use-regex` and `rewrite-target` annotations for the virtual host path
* `<release>`: the route to the frontend

With the Classic UI, it creates a single `<release>` Ingress to the backend, with the `use-regex` and `rewrite-target` annotations.

The annotations in `routing.ingressNginx.annotations` are added to all the Ingress resources, for example for cert-manager.
The chart doesn't use snippet annotations, which recent ingress-nginx versions reject by default.

When an Ingress with the `use-regex` annotation exists for a host, ingress-nginx treats the paths of all the Ingress resources of that host as regular expressions.
The paths created by this chart work either way.

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
