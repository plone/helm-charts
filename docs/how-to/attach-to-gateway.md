# How to attach the site to a Gateway

This guide shows you how to attach the HTTPRoute of the chart to a Gateway that already exists in your cluster.
The chart doesn't create the Gateway, nor the Gateway API CRDs or their implementation.
For background, see [Gateway API](../explanation/gateway-api.md).

## Prerequisites

* The Gateway API CRDs, and an implementation of them with a Gateway that serves your site
  See the [Gateway API guides](https://gateway-api.sigs.k8s.io/guides/) and the [list of implementations](https://gateway-api.sigs.k8s.io/implementations/).
  Many implementations install the CRDs themselves.

## Find the Gateway

List the Gateways of your cluster:

```shell
kubectl get gateways --all-namespaces
```

Note the name and namespace of the Gateway that serves your site, and the name of the listener you want to use, such as `https`.

## Attach the route to one Gateway

Set the name of the Gateway with `routing.gateway.name`, which is required with `routing.type: gateway`.
Set its namespace with `routing.gateway.namespace`, which defaults to the namespace of the release.
To restrict the route to one listener, set `routing.gateway.sectionName`:

```shell
helm install plone plone/plone --namespace plone --create-namespace \
    --set routing.hostname=plone.example.com \
    --set routing.gateway.name=<gateway> \
    --set routing.gateway.namespace=<gateway-namespace> \
    --set routing.gateway.sectionName=https
```

Replace `<gateway>` and `<gateway-namespace>` with the name and namespace of your Gateway, and `plone.example.com` with the hostname of the site.
The hostname must be one that the listener accepts.

## Attach the route to several Gateways

To attach the route to several Gateways, list them in `routing.gateway.parentRefs` instead, in the Gateway API format.
This takes precedence over `name`, `namespace`, and `sectionName`:

```yaml
routing:
  gateway:
    parentRefs:
      - name: public
        namespace: gateway-system
      - name: internal
        namespace: gateway-system
```

## Check that the Gateway accepted the route

```shell
kubectl describe httproute --namespace <namespace> <release>
```

The `Accepted` and `ResolvedRefs` conditions must be `True` for each Gateway.

For all the Gateway options, see [Routing](../reference/routing.md#gateway-api-routing).
