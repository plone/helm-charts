# Routing

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

## Gateway API routing

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
It's required with `routing.type: gateway`, and empty by default, because Gateway API has no default Gateway: the chart fails to install without it, rather than creating a route that no Gateway serves.
To install the chart without any routing, set `routing.type` to `none`.
Check that the Gateway accepted the route with:

```shell
kubectl describe httproute --namespace <namespace> <release>
```

## ingress-nginx routing

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
