# External PostgreSQL

Use a PostgreSQL server you already have, such as a managed cloud database, instead of a CloudNativePG cluster.
It works with Volto or the Classic UI, and with any routing.

## Prerequisites

* A PostgreSQL server reachable from the cluster, with a database and a user for Plone

It doesn't need the CloudNativePG operator.

## Values

Create a secret with the credentials:

```shell
kubectl create secret generic plonedb --namespace plone \
    --from-literal=database-name='plone' \
    --from-literal=database-user='plone' \
    --from-literal=database-password='<password>'
```

and point the chart to the server:

```yaml
postgresql:
  enabled: false
storage:
  relstorage:
    host: db.example.com
    port: 5432
    secret:
      name: plonedb
```

Install the chart with them:

```shell
helm install plone plone/plone --namespace plone --values values.yaml
```

If your secret uses other keys, for example one created by another tool, set them in `storage.relstorage.secret.keys`:

```yaml
storage:
  relstorage:
    secret:
      name: my-db-secret
      keys:
        database: dbname
        user: username
        password: password
```

## How it works

With `postgresql.enabled` set to `false`, the chart doesn't create a PostgreSQL cluster.
The backend connects to `storage.relstorage.host`, with the credentials from the `storage.relstorage.secret.name` secret.
RelStorage creates its tables in the database on the first start.
