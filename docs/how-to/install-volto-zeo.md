# How to install Plone with Volto and ZEO

This guide shows you how to install Plone 6 with the Volto frontend, storing its data in a ZEO server deployed by the chart, with a persistent volume.
Use it if you prefer the ZODB file storage over PostgreSQL, or to move an existing ZEO-based site.

## Prerequisites

* A [Gateway API](attach-to-gateway.md) implementation, and a Gateway

It doesn't need the CloudNativePG operator.

## Install

```shell
helm install plone plone/plone --namespace plone --create-namespace \
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

Requests flow as follows:

* `/++api++`: Gateway to the backend pods, then to the ZEO server
* everything else: Gateway to the frontend pods, which call the backend for server-side rendering

The ZEO server is a single pod: the backend pods can scale, but the ZEO server can't.
Its data is stored in a 5Gi persistent volume, which is kept when you uninstall the chart.
For all the ZEO options, see [Storage](../reference/storage.md#zeo).

`postgresql.enabled` must be `false`, so that the chart doesn't create a PostgreSQL cluster that Plone wouldn't use.

This scenario is tested by [`ci/zeo-values.yaml`](../../charts/plone/ci/zeo-values.yaml).
