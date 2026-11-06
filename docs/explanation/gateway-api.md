# About Gateway API

The chart routes the requests to Plone with a Gateway API HTTPRoute by default, and with Ingress resources for ingress-nginx as an option.
This page explains why the default is Gateway API, and what that means for the chart.

## Why Gateway API

The Ingress API has been frozen for years, and the ingress-nginx controller that most clusters used with it was [retired in March 2026](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/).
Gateway API is the successor of Ingress, and it is designed for the way clusters are run.
A cluster administrator owns a Gateway, which defines the listeners, the TLS certificates, and the addresses of the cluster.
An application owns the routes, which attach to a Gateway and send the requests of a hostname to its services.

The chart creates only the HTTPRoute, which is the part that belongs to the application.
The Gateway stays under the control of the cluster administrator, so the chart doesn't need the permissions to change the entry point of the cluster.

## What it means for the chart

Gateway API has no default Gateway, unlike Ingress with its default IngressClass.
So the chart requires `routing.gateway.name`, and fails to install without it, rather than create a route that no Gateway serves.
With `routing.type` set to `none`, the chart doesn't create any routing.

The HTTPRoute uses only the features of the standard channel of Gateway API, such as the `URLRewrite` filter with `ReplacePrefixMatch`.
So the same chart works with any conformant implementation, such as Envoy Gateway, Traefik, Istio, Cilium, or NGINX Gateway Fabric.
See the [list of implementations](https://gateway-api.sigs.k8s.io/implementations/).

## What it doesn't cover

The chart doesn't install the Gateway API CRDs, an implementation, or a Gateway.
Many implementations install the CRDs themselves, and the cluster administrator creates the Gateway.
For how to attach the site to a Gateway, see [How to attach the site to a Gateway](../how-to/attach-to-gateway.md).

The ingress-nginx routing is still available, for clusters that still run ingress-nginx.
It is meant for those clusters, not for new installations.
See [How to route the site with ingress-nginx](../how-to/use-ingress-nginx.md).
