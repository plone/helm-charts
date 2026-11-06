# Plone Helm chart

This chart installs [Plone 6](https://plone.org) on Kubernetes.
A single chart covers the common ways to run Plone, selected with a few values:

* **User interface:** the Volto frontend (default), or the Classic UI rendered by the backend
* **Storage:** RelStorage on PostgreSQL (default), or a ZEO server
* **Database:** a PostgreSQL cluster managed by CloudNativePG (default), or an external PostgreSQL server
* **Cache:** an optional Varnish cache in front of the site
* **Routing:** a Gateway API HTTPRoute (default), Ingress resources for ingress-nginx, or none

The full documentation, with the prerequisites, the scenarios, and the configuration, is in the [repository README](https://github.com/plone/helm-charts#readme).

## Quick start

The default scenario needs the [CloudNativePG operator](https://github.com/plone/helm-charts/blob/main/docs/prerequisites/cloudnativepg.md):

```shell
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm upgrade --install cnpg cnpg/cloudnative-pg \
    --namespace cnpg-system --create-namespace --wait
```

To try Plone without setting up routing:

```shell
helm repo add plone https://plone.github.io/helm-charts
helm install plone plone/plone --namespace plone --create-namespace \
    --set routing.type=none
kubectl port-forward --namespace plone service/plone-frontend 3000:3000
```

A Job creates the Plone site after the install, which takes a few minutes, and `helm install` waits for it.
Then open http://localhost:3000.

## Scenarios

* [Volto with PostgreSQL](https://github.com/plone/helm-charts/blob/main/docs/scenarios/volto-postgresql.md) (default)
* [Volto with PostgreSQL and Varnish](https://github.com/plone/helm-charts/blob/main/docs/scenarios/volto-postgresql-varnish.md)
* [Volto with ZEO](https://github.com/plone/helm-charts/blob/main/docs/scenarios/volto-zeo.md)
* [Classic UI with PostgreSQL](https://github.com/plone/helm-charts/blob/main/docs/scenarios/classic-postgresql.md)
* [Classic UI with ZEO](https://github.com/plone/helm-charts/blob/main/docs/scenarios/classic-zeo.md)
* [External PostgreSQL](https://github.com/plone/helm-charts/blob/main/docs/scenarios/external-postgresql.md)
* [External ZEO server](https://github.com/plone/helm-charts/blob/main/docs/scenarios/external-zeo.md)
* [ingress-nginx routing](https://github.com/plone/helm-charts/blob/main/docs/scenarios/ingress-nginx.md)
* [No routing](https://github.com/plone/helm-charts/blob/main/docs/scenarios/no-routing.md)

All values are documented in [`values.yaml`](values.yaml).
