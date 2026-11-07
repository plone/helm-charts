# Plone Helm chart

This chart installs [Plone 6](https://6.docs.plone.org/) on Kubernetes.
A single chart covers the common ways to run Plone, selected with a few values:

* **User interface:** the Volto frontend (default), or the Classic UI rendered by the backend
* **Storage:** RelStorage on PostgreSQL (default), or a ZEO server
* **Database:** a PostgreSQL cluster managed by CloudNativePG (default), or an external PostgreSQL server
* **Cache:** an optional Varnish cache in front of the site
* **Routing:** a Gateway API HTTPRoute (default), Ingress resources for ingress-nginx, or none

## Quick start

The default scenario needs the [CloudNativePG operator](https://github.com/plone/helm-charts/blob/main/docs/how-to/install-cloudnativepg.md).
To try Plone without routing:

```shell
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm upgrade --install cnpg cnpg/cloudnative-pg \
    --namespace cnpg-system --create-namespace --wait
helm repo add plone https://plone.github.io/helm-charts
helm install plone plone/plone --namespace plone --create-namespace \
    --set routing.type=none
kubectl port-forward --namespace plone service/plone-frontend 3000:3000
```

A Job creates the Plone site after the install, which takes a few minutes, and `helm install` waits for it.
Then open http://localhost:3000.

## Documentation

The full documentation is in the [repository](https://github.com/plone/helm-charts/blob/main/docs/index.md):

* [Tutorial: install Plone on Rancher Desktop](https://github.com/plone/helm-charts/blob/main/docs/tutorials/install-plone-on-rancher-desktop.md)
* [How-to guides](https://github.com/plone/helm-charts/blob/main/docs/how-to/index.md), with the scenarios, routing, and operations
* [Values reference](https://github.com/plone/helm-charts/blob/main/docs/reference/values.md)
* [Explanation](https://github.com/plone/helm-charts/blob/main/docs/explanation/index.md)
