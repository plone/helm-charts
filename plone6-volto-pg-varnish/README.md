# Install Plone 6 with RelStorage/PostgreSQL, Volto, and Varnish

This Helm chart combines the CloudNativePG PostgreSQL cluster, backend, and frontend subcharts with the community [Varnish Cache chart](https://github.com/varnish/helm-varnish-cache) to install Plone 6 with RelStorage/PostgreSQL as the database backend, Volto frontend, and Varnish as a cache server.
Requests are routed by a [Gateway API](https://gateway-api.sigs.k8s.io) HTTPRoute (the default), or by Ingress resources for the ingress-nginx controller.

Requests flow as follows:

* `/++api++` requests: Gateway or ingress controller → Varnish → backend pods
* everything else: Gateway or ingress controller → frontend

## Prerequisites

* The [CloudNativePG](https://cloudnative-pg.io) operator must be installed in your Kubernetes cluster.
  See [Install the operator](../README.md#install-the-operator).
* For the default `gateway` routing: the Gateway API CRDs, a Gateway API implementation, and a Gateway.
  See [Gateway API](#gateway-api).
* For the `ingress-nginx` routing: the ingress-nginx controller.
  See [ingress-nginx](#ingress-nginx).

## Routing

The chart replaces a reverse proxy in front of Plone with routing rules for your Gateway or ingress controller:

* `/++api++` requests go to Varnish, and through it to the backend.
  Their path is rewritten for the Zope virtual host monster, for example `/++api++/news` becomes `/VirtualHostBase/https/plone.example.com:443/Plone/++api++/VirtualHostRoot/news`, so that the backend generates URLs with the public hostname.
* `/static` requests go to the frontend, with a `Cache-Control` header that lets browsers cache the static assets for a year.
* Everything else goes to the frontend.

Choose the routing with `routing.type`:

| `routing.type` | Resources | Needs |
|---|---|---|
| `gateway` (default) | One `HTTPRoute` | Gateway API CRDs, an implementation, and a Gateway |
| `ingress-nginx` | Two or three `Ingress` resources | The ingress-nginx controller |
| `none` | Nothing | Your own routing to the `<release>-varnish` and `<release>-frontend` services |

The options shared by both routing types are:

```yaml
routing:
  # Public hostname of the site.
  hostname: plone.example.com
  # Whether clients use HTTPS, and on which port. The port defaults to 443
  # with HTTPS and 80 without. Both are used in the virtual host URLs.
  https: true
  port: ""
  # Id of the Plone site object in Zope.
  siteId: Plone
  staticCache:
    enabled: true
    cacheControl: "public, max-age=31536000"
```

TLS itself is terminated by the Gateway or the ingress controller, not by Plone.
`routing.https` only tells Plone which scheme and port the clients use.

### Gateway API

With `routing.type: gateway`, the chart creates an `HTTPRoute` attached to an existing Gateway.
It only uses features of the Gateway API standard channel (`URLRewrite` with `ReplacePrefixMatch`, and `ResponseHeaderModifier`), so it works with any conformant implementation, such as [Envoy Gateway](https://gateway.envoyproxy.io), [Traefik](https://doc.traefik.io/traefik/routing/providers/kubernetes-gateway/), [Istio](https://istio.io/latest/docs/tasks/traffic-management/ingress/gateway-api/), [Cilium](https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/gateway-api/), or [NGINX Gateway Fabric](https://docs.nginx.com/nginx-gateway-fabric/).
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

#### Attach the chart to the Gateway

Point `routing.gateway.parentRefs` to the Gateway:

```yaml
routing:
  type: gateway
  hostname: plone.example.com
  https: true
  gateway:
    parentRefs:
      - name: plone
        namespace: gateway-system
        sectionName: https
```

Check that the Gateway accepted the route with:

```shell
kubectl describe httproute <release>
```

### ingress-nginx

> [!WARNING]
> The [ingress-nginx](https://kubernetes.github.io/ingress-nginx/) project was [retired in March 2026](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/), and gets no more releases or security fixes.
> This routing type is meant for clusters that still run it.
> Prefer Gateway API for new installations.
> The NGINX Ingress Controller by F5 is a different product with different annotations, and isn't supported by this routing type.

With `routing.type: ingress-nginx`, the chart creates:

* `<release>-api`: the `/++api++` route, with the `use-regex` and `rewrite-target` annotations for the virtual host path
* `<release>`: the route to the frontend
* `<release>-static`: the route to the static assets of the frontend, only when `routing.ingressNginx.allowSnippets` is `true`

```yaml
routing:
  type: ingress-nginx
  hostname: plone.example.com
  https: true
  ingressNginx:
    className: nginx
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
    tls:
      - secretName: plone-tls
        hosts:
          - plone.example.com
    allowSnippets: false
```

The annotations in `routing.ingressNginx.annotations` are added to all the Ingress resources.

ingress-nginx can only set the `Cache-Control` header of static assets with the `configuration-snippet` annotation.
Recent ingress-nginx versions reject snippet annotations unless the controller has `allow-snippet-annotations` enabled, and also its `annotations-risk-level` set to `Critical`, because snippets have been the source of security issues.
Only set `allowSnippets` to `true` if your controller allows them.
Otherwise, the static assets are served with the headers set by the frontend.

Note that when an Ingress with the `use-regex` annotation exists for a host, ingress-nginx treats the paths of all Ingress resources of that host as regular expressions.
The paths created by this chart work either way.

## Database

This chart depends on the CloudNativePG `cluster` chart, under the alias `postgresql`.
By default, it creates a single-instance PostgreSQL cluster with a `plone` database.
The operator creates the database volume and generates the credentials in the `<release>-postgresql-app` secret, which the backend uses to connect to the `<release>-postgresql-rw` service.
You don't need to create a PersistentVolumeClaim or a credentials secret.

Set the options of the `cluster` chart under the `postgresql` key, for example for high availability:

```yaml
postgresql:
  cluster:
    instances: 3
    enablePDB: true
```

To use an external database instead, set `postgresql.enabled` to `false` and configure `backend.databasehost` and `backend.dbsecret`.
See [PostgreSQL with CloudNativePG](../README.md#postgresql-with-cloudnativepg) for details.

## Varnish

This repository does not ship its own Varnish chart.
Instead, this chart depends on the `varnish-cache` chart maintained by Varnish Software, published at `oci://registry-1.docker.io/varnish/varnish-cache`.
It is declared in `Chart.yaml` with the alias `varnish`, so its resources are named `<release>-varnish`, which is the service the `/++api++` route points to:

```yaml
dependencies:
  - name: "varnish-cache"
    alias: "varnish"
    version: "1.1.1"
    repository: "oci://registry-1.docker.io/varnish"
```

The route uses the port set in `varnish.server.service.http.port`.

### Configuration

The default `values.yaml` configures the community chart as follows:

* two Varnish replicas, run as a StatefulSet, with a PodDisruptionBudget of `minAvailable: 50%`
* a `ClusterIP` service on port `6081`
* a VCL that load balances requests between the backend pods in round-robin, addressing each pod through the headless `<release>-backend-director` service

```yaml
varnish:
  ploneBackendReplicas: 2
  server:
    kind: StatefulSet
    replicas: 2
    pdb:
      enabled: true
      minAvailable: 50%
    service:
      type: ClusterIP
      http:
        port: 6081
    vclConfig: |
      vcl 4.1;

      import directors;

      {{- $name := .Release.Name -}}
      {{- $replicas := .Values.ploneBackendReplicas | int -}}
      {{- range until $replicas }}
      backend backend{{ . }} {
          .host = "{{ $name }}-backend-{{ . }}.{{ $name }}-backend-director";
          .port = "8080";
      }
      {{- end }}

      sub vcl_init {
          new vdir = directors.round_robin();
          {{- range until $replicas }}
          vdir.add_backend(backend{{ . }});
          {{- end }}
      }

      sub vcl_recv {
          set req.backend_hint = vdir.backend();
      }
```

`server.vclConfig` is rendered as a Helm template, so it can use `.Release.Name` and values of the `varnish` section.
If you change `backend.replicaCount`, set `varnish.ploneBackendReplicas` to the same number, so that the VCL declares one backend per pod:

```yaml
backend:
  replicaCount: 3
varnish:
  ploneBackendReplicas: 3
```

To use your own VCL, override `varnish.server.vclConfig`.
See the [varnish-cache chart documentation](https://github.com/varnish/helm-varnish-cache) for all available options, such as resources, autoscaling, and `varnishncsa` logging.

### Using Varnish in your own composite chart

To put Varnish in front of the Plone backend in your own composite chart, add the same dependency and values to it, then run `helm dependency update` to fetch the chart.

