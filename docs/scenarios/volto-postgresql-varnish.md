# Volto with PostgreSQL and Varnish

The [default scenario](volto-postgresql.md), with a Varnish cache in front of the site.
Varnish receives all the requests, and sends the ones it doesn't cache to the backend or the frontend.

## Prerequisites

* The [CloudNativePG operator](../prerequisites/cloudnativepg.md)
* A [Gateway API](../../README.md#gateway-api) implementation, and a Gateway

## Install

```shell
helm install plone plone/plone --namespace plone --create-namespace \
    --set varnish.enabled=true \
    --set routing.hostname=plone.example.com \
    --set routing.gateway.name=<gateway> \
    --set routing.gateway.namespace=<gateway-namespace>
```

Replace `<gateway>` and `<gateway-namespace>` with the name and namespace of the Gateway that serves the site, and `plone.example.com` with its hostname.
The site is served over HTTP. To serve it over HTTPS, see [HTTPS](../components/routing.md#https).

## How it works

Requests flow as follows:

* `/++api++`: Gateway → Varnish → backend pods → PostgreSQL
* everything else, the pages and static assets of the site: Gateway → Varnish → frontend pods

Varnish is installed with the `varnish-cache` chart of Varnish Software, as a Deployment with one pod.
See [Varnish](../components/varnish.md) to customize the VCL.

Varnish can be added to any other scenario in the same way, with `--set varnish.enabled=true`.
With the Classic UI, also set `--set varnish.ploneFrontend=false`, see [Varnish](../components/varnish.md#vcl).

This scenario, with ingress-nginx routing, is tested by [`ci/varnish-ingress-nginx-values.yaml`](../../charts/plone/ci/varnish-ingress-nginx-values.yaml).
