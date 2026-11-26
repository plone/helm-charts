# Plone Helm chart

This chart installs [Plone 6](https://6.docs.plone.org/) on Kubernetes.
A single chart covers the common ways to run Plone, selected with a few values:

* **User interface:** the Volto frontend (default), or the Classic UI rendered by the backend
* **Storage:** RelStorage on PostgreSQL (default), or a ZEO server
* **Database:** a PostgreSQL cluster managed by CloudNativePG (default), or an external PostgreSQL server
* **Cache:** an optional Varnish cache in front of the site
* **Routing:** a Gateway API HTTPRoute (default), Ingress resources for ingress-nginx, or none

The chart is in **beta**: its defaults install a minimal site without backups, and some operations, such as backups and upgrades, aren't covered yet.
See [what isn't covered yet](https://plone.github.io/helm-charts/#beta).

## Quick start

The default scenario needs the [CloudNativePG operator](https://plone.github.io/helm-charts/how-to/install-cloudnativepg.html).
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
Then open http://localhost:3000, and log in as `admin`, with the password that the chart generated:

```shell
kubectl get secret --namespace plone plone-admin -o jsonpath='{.data.password}' | base64 -d
```

## Documentation

The full documentation is published at [plone.github.io/helm-charts](https://plone.github.io/helm-charts/):

* [Tutorial: install Plone on Rancher Desktop](https://plone.github.io/helm-charts/tutorials/install-plone-on-rancher-desktop.html)
* [How-to guides](https://plone.github.io/helm-charts/how-to/index.html), with the scenarios, routing, and operations
* [Values reference](https://plone.github.io/helm-charts/reference/values.html)
* [Explanation](https://plone.github.io/helm-charts/explanation/index.html)
