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

With the Classic UI, enable Varnish the same way.
The default VCL follows `frontend.enabled`, and sends all the requests to the backend when there is no frontend:

```shell
helm install plone plone/plone --namespace plone --create-namespace \
    --set frontend.enabled=false \
    --set varnish.enabled=true \
    --set routing.hostname=plone.example.com \
    --set routing.gateway.name=<gateway> \
    --set routing.gateway.namespace=<gateway-namespace>
```

The VCL also follows `fullnameOverride`, `backend.service.port`, and `frontend.service.port`, so there is nothing else to set when you change them.

## Run more Varnish pods

To run more Varnish pods, set `varnish.server.replicas`, and enable its PodDisruptionBudget when you do.
See [How to scale and make the site highly available](scale-and-high-availability.md).

## Change the VCL

To change the caching rules, see [How to customize the Varnish VCL](customize-varnish-vcl.md).
