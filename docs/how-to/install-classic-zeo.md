# How to install Plone with the Classic UI and ZEO

This guide shows you how to install Plone 6 with the Classic UI, rendered by the backend, without the Volto frontend, storing its data in a ZEO server deployed by the chart.

## Prerequisites

* A [Gateway API](attach-to-gateway.md) implementation, and a Gateway

It doesn't need the CloudNativePG operator.

## Install

```shell
helm install plone plone/plone --namespace plone --create-namespace \
    --set frontend.enabled=false \
    --set storage.type=zeo \
    --set postgresql.enabled=false \
    --set routing.hostname=plone.example.com \
    --set routing.gateway.name=<gateway> \
    --set routing.gateway.namespace=<gateway-namespace>
```

Replace `<gateway>` and `<gateway-namespace>` with the name and namespace of the Gateway that serves the site, and `plone.example.com` with its hostname.
The site is served over HTTP.
To serve it over HTTPS, see [How to serve the site over HTTPS](enable-https.md).

## How it works

All requests go from the Gateway to the backend pods, rewritten to the Zope virtual host path of the site, and the backend pods are clients of the ZEO server.

This combines [Classic UI with PostgreSQL](install-classic-postgresql.md) and [Volto with ZEO](install-volto-zeo.md).
See them for the details.

This scenario, with Varnish, is tested by [`ci/classic-zeo-varnish-values.yaml`](../../charts/plone/ci/classic-zeo-varnish-values.yaml).
