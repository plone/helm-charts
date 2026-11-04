# ingress-nginx routing

Replace the Gateway API HTTPRoute with Ingress resources for the ingress-nginx controller.
It works with any of the other scenarios.

> [!WARNING]
> The ingress-nginx project was [retired in March 2026](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/), and gets no more releases or security fixes.
> Prefer Gateway API for new installations.

## Prerequisites

* The [ingress-nginx controller](../../README.md#ingress-nginx)
* The prerequisites of the scenario it's combined with, except Gateway API

## Values

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
```

Install the chart with them:

```shell
helm install plone plone/plone --namespace plone --create-namespace --values values.yaml
```

## How it works

With Volto, the chart creates two Ingress resources:

* `<release>-api`: `/++api++` to the backend (or Varnish), rewritten to the Zope virtual host path with the `use-regex` and `rewrite-target` annotations
* `<release>`: everything else to the frontend

With the Classic UI, it creates a single `<release>` Ingress, sending everything to the backend (or Varnish), rewritten to the Zope virtual host path.

See [ingress-nginx routing](../components/routing.md#ingress-nginx-routing) for the details.

Combined with Varnish, this scenario is tested by [`ci/varnish-ingress-nginx-values.yaml`](../../charts/plone/ci/varnish-ingress-nginx-values.yaml).
