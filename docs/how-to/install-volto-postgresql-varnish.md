# How to install Plone with Volto, PostgreSQL, and Varnish

This guide shows you how to install the [default scenario](install-volto-postgresql.md) with a Varnish cache in front of the site.
Varnish receives all the requests, and sends the ones it doesn't cache to the backend or the frontend.

## Prerequisites

* The [CloudNativePG operator](install-cloudnativepg.md)
* A [Gateway API](attach-to-gateway.md) implementation, and a Gateway

## Install

```shell
helm install plone plone/plone --namespace plone --create-namespace \
    --set varnish.enabled=true \
    --set routing.hostname=plone.example.com \
    --set routing.gateway.name=<gateway> \
    --set routing.gateway.namespace=<gateway-namespace>
```

Replace `<gateway>` and `<gateway-namespace>` with the name and namespace of the Gateway that serves the site, and `plone.example.com` with its hostname.
The site is served over HTTP.
To serve it over HTTPS, see [How to serve the site over HTTPS](enable-https.md).

```{warning}
`helm uninstall` deletes the PostgreSQL cluster of the release, and with it its volumes and the content of the site.
See [Uninstalling](../reference/storage.md#uninstalling).
```

## How it works

Requests flow as follows:

* `/++api++`: Gateway to Varnish, then to the backend pods, then to PostgreSQL
* everything else, the pages and static assets of the site: Gateway to Varnish, then to the frontend pods

Varnish runs as a Deployment with one pod.
To change what Varnish caches, see [How to customize the Varnish VCL](customize-varnish-vcl.md).
For the default caching behavior, see [Varnish](../reference/varnish.md).

Varnish can be added to any other scenario in the same way, with `--set varnish.enabled=true`.
With the Classic UI, see [How to cache the site with Varnish](cache-with-varnish.md#use-varnish-with-the-classic-ui).

This scenario, with ingress-nginx routing, is tested by [`ci/varnish-ingress-nginx-values.yaml`](../../charts/plone/ci/varnish-ingress-nginx-values.yaml).
