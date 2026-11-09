# How to cache the site with Varnish

This guide shows you how to put a Varnish cache in front of the site, with the default VCL.
Varnish receives all the requests of the site, and sends them to the backend and the frontend.

## Enable Varnish

Set `varnish.enabled` to `true`, with the routing of your scenario.
For example, with the default scenario:

```shell
helm install plone plone/plone --namespace plone --create-namespace \
    --set varnish.enabled=true \
    --set routing.hostname=plone.example.com \
    --set routing.gateway.name=<gateway> \
    --set routing.gateway.namespace=<gateway-namespace>
```

Replace `<gateway>` and `<gateway-namespace>` with the name and namespace of your Gateway, and `plone.example.com` with the hostname of the site.
The scenario [How to install Plone with Volto, PostgreSQL, and Varnish](install-volto-postgresql-varnish.md) shows the full installation.

For what Varnish caches by default, see [Varnish](../reference/varnish.md).

## Use Varnish with the Classic UI

With the Classic UI, also set `varnish.ploneFrontend` to `false`.
The default VCL can't read the values of this chart, such as `frontend.enabled`, so it needs this value to know that the frontend doesn't exist:

```shell
helm install plone plone/plone --namespace plone --create-namespace \
    --set frontend.enabled=false \
    --set varnish.enabled=true \
    --set varnish.ploneFrontend=false \
    --set routing.hostname=plone.example.com \
    --set routing.gateway.name=<gateway> \
    --set routing.gateway.namespace=<gateway-namespace>
```

The chart fails with an explanation when `varnish.ploneFrontend` doesn't match `frontend.enabled`.

## Change the Service names or ports

For the same reason, the VCL gets the Services from the global values, the only ones that the two charts share.
If you change `fullnameOverride`, `backend.service.port`, or `frontend.service.port`, set the same value in `global.plone`:

```yaml
fullnameOverride: web
backend:
  service:
    port: 80
frontend:
  service:
    port: 81
global:
  plone:
    fullnameOverride: web
    backendPort: 80
    frontendPort: 81
```

The chart fails with an explanation when they don't match.

## Run more Varnish pods

To run more Varnish pods, set `varnish.server.replicas`, and enable its PodDisruptionBudget when you do.
See [How to scale and make the site highly available](scale-and-high-availability.md).

## Change the VCL

To change the caching rules, see [How to customize the Varnish VCL](customize-varnish-vcl.md).
