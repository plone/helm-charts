# Volto with PostgreSQL and Varnish

The [default scenario](volto-postgresql.md), with a Varnish cache in front of the backend.
Varnish sends the requests it doesn't cache to the backend Service, which balances them between the backend pods.

## Prerequisites

* The [CloudNativePG operator](../../README.md#cloudnativepg-operator)
* [Gateway API](../../README.md#gateway-api): the CRDs, an implementation, and a Gateway

## Values

```yaml
varnish:
  enabled: true
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

* `/++api++`: Gateway → Varnish → backend pods → PostgreSQL
* everything else: Gateway → frontend pods

Varnish is installed with the `varnish-cache` chart of Varnish Software, as a Deployment with one pod.
See [Varnish](../components/varnish.md) to customize the VCL.

Varnish can be added to any other scenario in the same way, with `varnish.enabled: true`.

This scenario, with ingress-nginx routing, is tested by [`ci/varnish-ingress-nginx-values.yaml`](../../charts/plone/ci/varnish-ingress-nginx-values.yaml).
