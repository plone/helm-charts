# Volto with ZEO

Plone with the Volto frontend, storing its data in a ZEO server deployed by the chart, with a persistent volume.
Use it if you prefer the ZODB file storage over PostgreSQL, or to move an existing ZEO-based site.

## Prerequisites

* [Gateway API](../README.md#gateway-api): the CRDs, an implementation, and a Gateway

It doesn't need the CloudNativePG operator.

## Values

```yaml
storage:
  type: zeo
postgresql:
  enabled: false
routing:
  hostname: plone.example.com
  https: true
  gateway:
    parentRefs:
      - name: plone
        namespace: gateway-system
```

Install the chart with them:

```shell
helm install plone plone/plone --namespace plone --create-namespace --values values.yaml
```

## How it works

Requests flow as follows:

* `/++api++`: Gateway → backend pods → ZEO server
* everything else: Gateway → frontend pods, which call the backend for server-side rendering

ZEO is a single server: the backend pods can scale, but the ZEO server can't.
Its data is stored in a 5Gi persistent volume, which is kept when you uninstall the chart.
See [ZEO](../README.md#zeo) for its options.

`postgresql.enabled` must be `false`, so that the chart doesn't create a PostgreSQL cluster that Plone wouldn't use.

This scenario is tested by [`ci/zeo-values.yaml`](../charts/plone/ci/zeo-values.yaml).
