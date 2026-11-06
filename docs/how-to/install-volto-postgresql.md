# How to install Plone with Volto and PostgreSQL

This guide shows you how to install Plone 6 with the Volto frontend, storing its data, blobs included, in a PostgreSQL cluster managed by CloudNativePG.
This is the default scenario, and the recommended setup for new sites.

## Prerequisites

* The [CloudNativePG operator](install-cloudnativepg.md)
* A [Gateway API](attach-to-gateway.md) implementation, and a Gateway

## Install

```shell
helm install plone plone/plone --namespace plone --create-namespace \
    --set routing.hostname=plone.example.com \
    --set routing.gateway.name=<gateway> \
    --set routing.gateway.namespace=<gateway-namespace>
```

Replace `<gateway>` and `<gateway-namespace>` with the name and namespace of the Gateway that serves the site, and `plone.example.com` with its hostname.
The site is served over HTTP.
To serve it over HTTPS, see [How to serve the site over HTTPS](enable-https.md).

## How it works

Requests flow as follows:

* `/++api++`: Gateway to the backend pods, then to PostgreSQL
* everything else: Gateway to the frontend pods, which call the backend for server-side rendering

The chart creates a backend, a frontend, a PostgreSQL cluster with one instance, and an HTTPRoute attached to the Gateway.
For the list of resources, see [Resources by scenario](../reference/scenario-resources.md).
To run more pods of each component, see [How to scale and make the site highly available](scale-and-high-availability.md).

This scenario is tested by [`ci/default-values.yaml`](../../charts/plone/ci/default-values.yaml).
