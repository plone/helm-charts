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
  https: false
  port: ""
```

`routing.https` and `routing.port` only tell Plone which scheme and port the clients use, for the URLs it generates.

## HTTPS

By default, the site is served over HTTP: `routing.https` is `false`, and the chart doesn't need any certificate.

TLS is terminated by the Gateway or the ingress controller, not by Plone, so serving the site over HTTPS needs a certificate for its hostname, in a Kubernetes TLS secret, used by:

* with Gateway API: an HTTPS listener of the Gateway, which references the secret in its `certificateRefs`. The Gateway is managed outside of this chart.
* with ingress-nginx: the Ingress resources of the chart, with `routing.ingressNginx.tls`.

The certificate can come from [cert-manager](https://cert-manager.io), which issues and renews certificates, for example from Let's Encrypt, but cert-manager isn't required: any TLS secret works, and some cloud load balancers terminate TLS themselves.

Once the site is served over HTTPS, set `routing.https` to `true`, so that Plone generates `https://` URLs.
Setting it doesn't create a certificate or configure TLS.

With Gateway API, attach the route to the HTTPS listener of the Gateway:

```shell
helm install plone plone/plone --namespace plone --create-namespace \
    --set routing.hostname=plone.example.com \
    --set routing.https=true \
    --set routing.gateway.name=<gateway> \
    --set routing.gateway.namespace=<gateway-namespace> \
    --set routing.gateway.sectionName=https
```

With ingress-nginx and cert-manager, which issues the certificate into the `plone-tls` secret:

```shell
helm install plone plone/plone --namespace plone --create-namespace \
    --set routing.type=ingress-nginx \
    --set routing.hostname=plone.example.com \
    --set routing.https=true \
    --set routing.ingressNginx.tls[0].secretName=plone-tls \
    --set routing.ingressNginx.tls[0].hosts[0]=plone.example.com \
    --set 'routing.ingressNginx.annotations.cert-manager\.io/cluster-issuer=letsencrypt-prod'
```

## Gateway API routing

```yaml
routing:
  type: gateway
  gateway:
    name: plone
    namespace: gateway-system
    sectionName: https
    annotations: {}
```

`routing.gateway.name` is the Gateway that the HTTPRoute attaches to, in the `routing.gateway.namespace` namespace, which defaults to the namespace of the release.
`routing.gateway.sectionName` optionally restricts the route to one listener of the Gateway, such as `https`.

The Gateway name is required with `routing.type: gateway`, and empty by default, because Gateway API has no default Gateway: the chart fails to install without it, rather than creating a route that no Gateway serves.
To install the chart without any routing, set `routing.type` to `none`.

To attach the route to several Gateways, list them in `routing.gateway.parentRefs` instead, in the Gateway API format, which takes precedence over the name, namespace, and section name:

```yaml
routing:
  gateway:
    parentRefs:
      - name: public
        namespace: gateway-system
      - name: internal
        namespace: gateway-system
```

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
