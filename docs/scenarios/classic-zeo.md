# Classic UI with ZEO

Plone with the Classic UI, rendered by the backend, without the Volto frontend, storing its data in a ZEO server deployed by the chart.

## Prerequisites

* A [Gateway API](../../README.md#gateway-api) implementation, and a Gateway

It doesn't need the CloudNativePG operator.

## Values

```yaml
frontend:
  enabled: false
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

All requests go from the Gateway to the backend pods, rewritten to the Zope virtual host path of the site, and the backend pods are clients of the ZEO server.

This combines [Classic UI with PostgreSQL](classic-postgresql.md) and [Volto with ZEO](volto-zeo.md), see them for the details.
