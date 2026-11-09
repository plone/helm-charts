# Routing

The routing sends the requests of the public hostname to the frontend and the backend.
`routing.type` selects the resources that it creates:

| `routing.type` | Resources | Routes |
|---|---|---|
| `gateway` (default) | an HTTPRoute, attached to an existing Gateway | Gateway API |
| `ingress-nginx` | Ingress resources for the ingress-nginx controller | ingress-nginx |
| `none` | no routing resources | your own routing |

## Shared options

```yaml
routing:
  # gateway, ingress-nginx, or none
  type: gateway
  # Public hostname of the site.
  hostname: localhost
  # Whether clients use HTTPS, and on which port. The port defaults to 443
  # with HTTPS and 80 without.
  https: false
  port: ""
```

`routing.https` and `routing.port` only tell Plone which scheme and port the clients use, for the URLs it generates.
TLS is terminated by the Gateway or the ingress controller, not by Plone.
The public URL of the site is `<scheme>://<hostname>`, with the port added when it isn't the default one.

## Virtual host paths

The backend requests are rewritten to a Zope virtual host path, with this format:

* with Volto: `/VirtualHostBase/<scheme>/<hostname>:<port>/<site.id>/++api++/VirtualHostRoot`
* with the Classic UI: `/VirtualHostBase/<scheme>/<hostname>:<port>/<site.id>/VirtualHostRoot`

With `routing.https` set to `false` and the default port, the scheme is `http` and the port is `80`.
For why the rewrite exists, see [The Zope virtual host rewrite](../explanation/virtual-host-rewrite.md).

## Gateway API routing

With `routing.type: gateway`, the chart creates the HTTPRoute `<release>`, with these rules:

| Scenario | Match | Rewrite | Backend |
|---|---|---|---|
| Volto | `/++api++`, path prefix | prefix replaced with the virtual host path | `<release>-backend` on port 8080, or `<release>-varnish` on port 6081 |
| Volto | `/`, path prefix | none | `<release>-frontend` on port 3000, or `<release>-varnish` on port 6081 |
| Classic UI | `/`, path prefix | prefix replaced with the virtual host path | `<release>-backend` on port 8080, or `<release>-varnish` on port 6081 |

The route uses the hostname `routing.hostname`.
The rewrite uses the `ReplacePrefixMatch` type, from the standard channel of the Gateway API.

The Gateway options are:

```yaml
routing:
  gateway:
    # The Gateway to attach to. Required, unless parentRefs is set.
    name: ""
    # Namespace of the Gateway. Defaults to the namespace of the release.
    namespace: ""
    # Listener of the Gateway, such as http or https. Defaults to all the
    # listeners that accept the route.
    sectionName: ""
    # Gateways to attach to, as Gateway API parentRefs. Takes precedence over
    # name, namespace, and sectionName.
    parentRefs: []
    # Annotations of the HTTPRoute.
    annotations: {}
```

Each `parentRefs` entry is a Gateway API parent reference, with `name`, `namespace`, and `sectionName`.
With `routing.type: gateway`, the chart fails to install when neither `routing.gateway.name` nor `routing.gateway.parentRefs` is set.

## ingress-nginx resources

With `routing.type: ingress-nginx`, the chart creates the following Ingress resources, for the `routing.ingressNginx.className` class (default `nginx`):

| Resource | Scenario | Path | Backend | Annotations |
|---|---|---|---|---|
| `<release>-api` | Volto only | `/\+\+api\+\+($\|/.*)` | backend or Varnish | `use-regex: "true"`, `rewrite-target` with the virtual host path followed by `$1` |
| `<release>` | Volto | `/`, prefix | frontend or Varnish | `routing.ingressNginx.annotations` |
| `<release>` | Classic UI | `/(.*)` | backend or Varnish | `use-regex: "true"`, `rewrite-target` with the virtual host path followed by `/$1`, and `routing.ingressNginx.annotations` |

The annotations in `routing.ingressNginx.annotations` are added to all the Ingress resources, for example for cert-manager.
`routing.ingressNginx.tls` sets the `tls` section of all the Ingress resources.
The chart doesn't use snippet annotations, which recent ingress-nginx versions reject by default.

When an Ingress with the `use-regex` annotation exists for a host, ingress-nginx treats the paths of all the Ingress resources of that host as regular expressions.
The paths created by this chart work either way.

For a step-by-step installation, see [How to route the site with ingress-nginx](../how-to/use-ingress-nginx.md).
