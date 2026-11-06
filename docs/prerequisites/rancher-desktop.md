# Rancher Desktop and k3s with Traefik

[Rancher Desktop](https://rancherdesktop.io) runs [k3s](https://k3s.io), which comes with Traefik as its ingress controller, and with the Gateway API CRDs.
Its Traefik doesn't serve Gateway API routes by default, though: without the steps below, the HTTPRoute of the chart isn't attached to any Gateway, and Traefik answers every request with a 404.

These steps are meant for a local cluster, to try the chart.
They apply to other k3s clusters with the bundled Traefik too.

## Enable the Gateway API provider of Traefik

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

## Install the chart

Install the chart, attaching its HTTPRoute to the `traefik-gateway` Gateway:

```shell
helm install plone plone/plone --namespace plone --create-namespace \
    --set routing.hostname=localhost \
    --set routing.gateway.name=traefik-gateway \
    --set routing.gateway.namespace=kube-system \
    --set routing.gateway.sectionName=web
```

The chart also needs the [CloudNativePG operator](cloudnativepg.md) for the default scenario.

Check that the Gateway accepted the route:

```shell
kubectl describe httproute plone -n plone
```

Its status must show the `Accepted` and `ResolvedRefs` conditions set to `True` for `traefik-gateway`.
Once the pods are ready, Plone is available at http://localhost, as Rancher Desktop forwards the port 80 of Traefik to your machine.

## Undo

To go back to the default Traefik configuration:

```shell
kubectl delete helmchartconfig traefik -n kube-system
```
