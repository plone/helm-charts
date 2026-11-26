# How to route the site with Traefik

This guide shows you how to route the site with Ingress resources for the Ingress provider of Traefik.
It is the way to route the site on k3s, whose Traefik serves Ingress resources, and doesn't need the Gateway API provider.
It works with any of the other scenarios.

## Prerequisites

* Traefik with its Kubernetes Ingress provider enabled, which is its default, and its IngressClass `traefik`.
  k3s installs Traefik this way.
* The prerequisites of the scenario it's combined with, except Gateway API.

## Install

```shell
helm install plone plone/plone --namespace plone --create-namespace \
    --set routing.type=traefik \
    --set routing.hostname=plone.example.com
```

Replace `plone.example.com` with the hostname of the site.
The Ingress resources use the `traefik` IngressClass.
To use another one, set `--set routing.traefik.className=<class>`.
Combine these values with the ones of any other scenario, for example `--set varnish.enabled=true`.

## Serve the site over HTTPS

With cert-manager, which issues the certificate into the `plone-tls` secret:

```shell
helm install plone plone/plone --namespace plone --create-namespace \
    --set routing.type=traefik \
    --set routing.hostname=plone.example.com \
    --set routing.https=true \
    --set routing.traefik.tls[0].secretName=plone-tls \
    --set routing.traefik.tls[0].hosts[0]=plone.example.com \
    --set 'routing.traefik.annotations.cert-manager\.io/cluster-issuer=letsencrypt-prod'
```

The annotations of `routing.traefik.annotations` are added to the Ingress resources, as the ones of `routing.ingressNginx.annotations` are with ingress-nginx.
The annotations of ingress-nginx, such as `rewrite-target`, don't apply to Traefik: the chart uses Middleware resources for the rewrites.

## How it works

With Volto, the chart creates two Ingress resources:

* `<release>-api`: `/++api++` to the backend (or Varnish), rewritten by a Traefik Middleware to the Zope virtual host path
* `<release>`: everything else to the frontend (or Varnish)

With the Classic UI, it creates a single `<release>` Ingress, sending everything to the backend (or Varnish), rewritten by a Middleware.

For the details of these resources, see [Routing](../reference/routing.md#traefik-resources).

The scenario is tested by [`ci/traefik-values.yaml`](../../charts/plone/ci/traefik-values.yaml), which the CI runs against the Traefik of `make cluster-deps`.
