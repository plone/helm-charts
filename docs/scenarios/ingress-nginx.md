# ingress-nginx routing

Replace the Gateway API HTTPRoute with Ingress resources for the ingress-nginx controller.
It works with any of the other scenarios.

> [!WARNING]
> The ingress-nginx project was [retired in March 2026](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/), and gets no more releases or security fixes.
> Prefer Gateway API for new installations.

## Prerequisites

* The [ingress-nginx controller](../../README.md#ingress-nginx)
* The prerequisites of the scenario it's combined with, except Gateway API

## Install

```shell
helm install plone plone/plone --namespace plone --create-namespace \
    --set routing.type=ingress-nginx \
    --set routing.hostname=plone.example.com
```

Replace `plone.example.com` with the hostname of the site.
The Ingress resources use the `nginx` IngressClass, set another one with `--set routing.ingressNginx.className=<class>`.
Combine these values with the ones of any other scenario, for example `--set varnish.enabled=true`.

The site is served over HTTP. To serve it over HTTPS, see [HTTPS](../components/routing.md#https).

## How it works

With Volto, the chart creates two Ingress resources:

* `<release>-api`: `/++api++` to the backend (or Varnish), rewritten to the Zope virtual host path with the `use-regex` and `rewrite-target` annotations
* `<release>`: everything else to the frontend (or Varnish)

With the Classic UI, it creates a single `<release>` Ingress, sending everything to the backend (or Varnish), rewritten to the Zope virtual host path.

See [ingress-nginx routing](../components/routing.md#ingress-nginx-routing) for the details.

Combined with Varnish, this scenario is tested by [`ci/varnish-ingress-nginx-values.yaml`](../../charts/plone/ci/varnish-ingress-nginx-values.yaml).
