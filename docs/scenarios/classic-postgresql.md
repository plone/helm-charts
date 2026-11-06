# Classic UI with PostgreSQL

Plone with the Classic UI, rendered by the backend, without the Volto frontend, storing its data in a PostgreSQL cluster managed by CloudNativePG.

## Prerequisites

* The [CloudNativePG operator](../prerequisites/cloudnativepg.md)
* A [Gateway API](../../README.md#gateway-api) implementation, and a Gateway

## Install

```shell
helm install plone plone/plone --namespace plone --create-namespace \
    --set frontend.enabled=false \
    --set routing.hostname=plone.example.com \
    --set routing.gateway.name=<gateway> \
    --set routing.gateway.namespace=<gateway-namespace>
```

Replace `<gateway>` and `<gateway-namespace>` with the name and namespace of the Gateway that serves the site, and `plone.example.com` with its hostname.
The site is served over HTTP. To serve it over HTTPS, see [HTTPS](../components/routing.md#https).

## How it works

All requests go from the Gateway to the backend pods, rewritten to the Zope virtual host path of the site.
For example, `/news` becomes `/VirtualHostBase/https/plone.example.com:443/Plone/VirtualHostRoot/news`.

The backend creates a Classic UI site on its first start.

This scenario is tested by [`ci/classic-values.yaml`](../../charts/plone/ci/classic-values.yaml).
