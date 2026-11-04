# Plone Helm Charts

![test](https://github.com/plone/helm-charts/actions/workflows/test.yml/badge.svg)

A collection of Helm Charts for Plone 6.
If you want to run Plone 6 on Kubernetes, this repository is a good starting point.
There are different ways to use this repository:

* Add a Helm repository, and use the published charts. See the next section on how to do that.
* As a library of subcharts that you can use to create your own composite charts

Even if you do not want to use Helm for your setup, `helm install --dry-run` might give you some ideas on how to deploy Plone on Kubernetes.

## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

`helm repo add plone https://plone.github.io/helm-charts`

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  Then, run `helm search repo
plone` to see the charts.

## PostgreSQL with CloudNativePG

The charts that use PostgreSQL (`plone6-classic-pg`, `plone6-volto-pg`, and `plone6-volto-pg-varnish`) don't ship their own database chart.
They create a PostgreSQL cluster with the [`cluster` chart](https://github.com/cloudnative-pg/charts/tree/main/charts/cluster) of [CloudNativePG](https://cloudnative-pg.io), a CNCF project.
The cluster is run by the CloudNativePG operator, which takes care of the database pods, volumes, credentials, failover, and backups.

### Install the operator

Install the operator once per Kubernetes cluster, before you install any of these charts.
It needs Kubernetes 1.29 or later, and permissions to create cluster-wide resources (CustomResourceDefinitions and ClusterRoles), usually as a cluster administrator.

With Helm:

```shell
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm upgrade --install cnpg cnpg/cloudnative-pg \
    --namespace cnpg-system --create-namespace --wait
```

Or with `kubectl`, from the release manifest:

```shell
kubectl apply --server-side -f \
    https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.30/releases/cnpg-1.30.1.yaml
kubectl rollout status deployment -n cnpg-system cnpg-controller-manager
```

Check that the operator is installed with:

```shell
kubectl get crd clusters.postgresql.cnpg.io
```

To upgrade the operator later, run the same commands with a newer version.
See the [CloudNativePG installation documentation](https://cloudnative-pg.io/documentation/current/installation_upgrade/) for other methods, such as OLM, and for upgrade notes.

### How the charts use it

The `cluster` chart is a dependency with the alias `postgresql`.
By default, it creates a PostgreSQL cluster named `<release>-postgresql` with:

* one instance, with an 8Gi volume created by the operator
* a `plone` database, owned by the `plone` user
* a `<release>-postgresql-app` secret with the generated credentials of the `plone` user
* a `<release>-postgresql-rw` service that always points to the primary instance

The backend connects to `<release>-postgresql-rw` with the credentials from `<release>-postgresql-app`.
You don't need to create a PersistentVolumeClaim or a credentials secret.

All options of the `cluster` chart can be set under the `postgresql` key.
For example, to run three instances with automatic failover:

```yaml
postgresql:
  cluster:
    instances: 3
    enablePDB: true
```

See the [`cluster` chart documentation](https://github.com/cloudnative-pg/charts/tree/main/charts/cluster) for backups, monitoring, connection pooling, and recovery.

If you install a chart from a checkout of this repository, add the `cnpg` Helm repository first, so that `helm dependency update` can fetch the `cluster` chart:

```shell
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm dependency update ./plone6-volto-pg
```

### Use an external database instead

If you can't install the operator, or you already have a PostgreSQL server, disable the `cluster` dependency and point the backend to your database:

```yaml
postgresql:
  enabled: false
backend:
  databasehost: your.db.host
  databaseport: 5432
  dbsecret:
    name: plonedb
    keys:
      database: database-name
      user: database-user
      password: database-password
```

The secret must contain the database name, user name, and password under the keys listed in `dbsecret.keys`.
You can create it with:

```shell
kubectl create secret generic plonedb \
    --from-literal=database-name='plone' \
    --from-literal=database-user='plone' \
    --from-literal=database-password='plone'
```

The `plone6-classic-nodb` chart works the same way, without the `cluster` dependency.

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

