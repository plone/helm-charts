# External ZEO server

Use a ZEO server you already have, instead of the ZEO server of the chart.
It works with Volto or the Classic UI, and with any routing.

## Prerequisites

* A ZEO server reachable from the cluster

It doesn't need the CloudNativePG operator.

## Values

```yaml
storage:
  type: zeo
  zeo:
    address: zeo.example.com:8100
postgresql:
  enabled: false
```

Install the chart with them:

```shell
helm install plone plone/plone --namespace plone --create-namespace --values values.yaml
```

## How it works

With `storage.zeo.address` set, the chart doesn't deploy a ZEO server, and the backend pods connect to the given address.
The pack CronJob packs the external server with `zeopack`; set `pack.enabled` to `false` if the server is packed elsewhere.
