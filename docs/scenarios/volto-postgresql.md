# Volto with PostgreSQL (default)

Plone with the Volto frontend, storing its data, blobs included, in a PostgreSQL cluster managed by CloudNativePG.
This is the default scenario, and the recommended setup for new sites.

## Prerequisites

* The [CloudNativePG operator](../prerequisites/cloudnativepg.md)
* A [Gateway API](../../README.md#gateway-api) implementation, and a Gateway

## Install

```shell
helm install plone plone/plone --namespace plone --create-namespace \
    --set routing.hostname=plone.example.com \
    --set routing.gateway.name=<gateway> \
    --set routing.gateway.namespace=<gateway-namespace>
```

Replace `<gateway>` and `<gateway-namespace>` with the name and namespace of the Gateway that serves the site, and `plone.example.com` with its hostname.
The site is served over HTTP. To serve it over HTTPS, see [HTTPS](../components/routing.md#https).

## How it works

Requests flow as follows:

* `/++api++`: Gateway → backend pods → PostgreSQL
* everything else: Gateway → frontend pods, which call the backend for server-side rendering

The chart creates:

* the backend StatefulSet, with one pod
* the frontend Deployment, with one pod
* a PostgreSQL cluster with one instance
* an HTTPRoute attached to the Gateway, see [Gateway API routing](../components/routing.md#gateway-api-routing)

See [Replicas and high availability](../components/high-availability.md) to run more pods of each.

This scenario is tested by [`ci/default-values.yaml`](../../charts/plone/ci/default-values.yaml).
