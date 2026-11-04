# Classic UI with PostgreSQL

Plone with the Classic UI, rendered by the backend, without the Volto frontend, storing its data in a PostgreSQL cluster managed by CloudNativePG.

## Prerequisites

* The [CloudNativePG operator](../../README.md#cloudnativepg-operator)
* [Gateway API](../../README.md#gateway-api): the CRDs, an implementation, and a Gateway

## Values

```yaml
frontend:
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

All requests go from the Gateway to the backend pods, rewritten to the Zope virtual host path of the site.
For example, `/news` becomes `/VirtualHostBase/https/plone.example.com:443/Plone/VirtualHostRoot/news`.

The backend creates a Classic UI site on its first start.

This scenario is tested by [`ci/classic-values.yaml`](../../charts/plone/ci/classic-values.yaml).
