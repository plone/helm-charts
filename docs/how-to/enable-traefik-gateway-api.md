# How to enable the Gateway API provider of Traefik on k3s

This guide shows you how to enable the Gateway API provider of the Traefik that comes with k3s, for example in Rancher Desktop, so that the HTTPRoute of the chart is served.
It applies to other k3s clusters with the bundled Traefik too.
These steps are meant for a local cluster, to try the chart.

Without these steps, the HTTPRoute of the chart isn't attached to any Gateway, and Traefik answers every request with a 404.

## Enable the provider

k3s configures its Traefik with a `HelmChartConfig`.
Create one that enables the Gateway API provider, and lets the `web` listener of its Gateway accept routes from other namespaces:

```yaml
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    providers:
      kubernetesGateway:
        enabled: true
    gateway:
      listeners:
        web:
          namespacePolicy:
            from: All
```

Save it as `traefik-gateway.yaml`, then apply it:

```shell
kubectl apply -f traefik-gateway.yaml
```

k3s redeploys Traefik, which creates the `traefik` GatewayClass, and the `traefik-gateway` Gateway in the `kube-system` namespace, with an HTTP listener named `web` on port 80.
Wait for the Gateway to be ready:

```shell
kubectl wait --for=create gateway/traefik-gateway -n kube-system --timeout=240s
kubectl wait --for=condition=Programmed gateway/traefik-gateway -n kube-system --timeout=180s
```

If you already have a `HelmChartConfig` named `traefik`, add these values to it instead.

## Attach the chart to the Gateway

Install the chart with its HTTPRoute attached to `traefik-gateway`:

```shell
helm install plone plone/plone --namespace plone --create-namespace \
    --set routing.hostname=localhost \
    --set routing.gateway.name=traefik-gateway \
    --set routing.gateway.namespace=kube-system \
    --set routing.gateway.sectionName=web
```

The chart also needs the [CloudNativePG operator](install-cloudnativepg.md) for the default scenario.
For the other options of the Gateway, see [How to attach the site to a Gateway](attach-to-gateway.md).

Check that the Gateway accepted the route:

```shell
kubectl describe httproute plone -n plone
```

The `Accepted` and `ResolvedRefs` conditions must be `True` for `traefik-gateway`.
Once the pods are ready, Plone is available at http://localhost, as Rancher Desktop forwards the port 80 of Traefik to your machine.

## Undo

To go back to the default Traefik configuration:

```shell
kubectl delete helmchartconfig traefik -n kube-system
```
