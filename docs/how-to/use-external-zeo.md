# How to use an external ZEO server

This guide shows you how to store the Plone database in a ZEO server you already have, instead of the ZEO server of the chart.
It works with Volto or the Classic UI, and with any routing.

## Prerequisites

* A ZEO server reachable from the cluster

It doesn't need the CloudNativePG operator.

## Install

```shell
helm install plone plone/plone --namespace plone --create-namespace \
    --set storage.type=zeo \
    --set storage.zeo.address=zeo.example.com:8100 \
    --set postgresql.enabled=false \
    --set routing.hostname=plone.example.com \
    --set routing.gateway.name=<gateway> \
    --set routing.gateway.namespace=<gateway-namespace>
```

Replace `<gateway>` and `<gateway-namespace>` with the name and namespace of the Gateway that serves the site, and `plone.example.com` with its hostname.
Replace `zeo.example.com:8100` with the address of your ZEO server.
Combine these values with the ones of any other scenario, for example `--set frontend.enabled=false` for the Classic UI.

## How it works

With `storage.zeo.address` set, the chart doesn't deploy a ZEO server, and the backend pods connect to the given address.
The pack CronJob packs the external server with `zeopack`.
Set `pack.enabled` to `false` if the server is packed elsewhere.
