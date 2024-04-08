# Plone Helm Charts

![test](https://github.com/plone/helm-charts/actions/workflows/test.yml/badge.svg)

Helm Charts for Plone 6. 

## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

`helm repo add plone https://plone.github.io/helm-charts`

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  Then, run `helm search repo
plone` to see the charts.

## Plone quick start

### With Nginx Ingress Controller

To install plone with a ZEO Server and on a Kubernetes cluster with Nginx Ingress Controller, first, create a `values.yaml` file with the content:

```
ingress:
  className: "nginx"
  hosts:
    - host: your.plone.url
      paths:
        - path: /
          pathType: ImplementationSpecific
```

Then, to install Plone in `plone` namespace, naming the release `plone6`, run:

```
helm install -n plone plone6 plone/plone --values values.yaml
```

### Without an Ingress Controller

If you don't have an Ingress Controller installed:

```
helm install -n plone plone6 plone/plone --set ingress.enabled=false
```

Use `kubectl port-forward` to map your local `3000` port onto port `3000` of your `plone-frontend` service:

```
kubectl port-forward -n plone service/plone6-frontend 3000:3000
```

You can now access your Plone 6 installation by pointing your web browser to `http://localhost:3000`.

