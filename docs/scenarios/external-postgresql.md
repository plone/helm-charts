# External PostgreSQL

Use a PostgreSQL server you already have, such as a managed cloud database, instead of a CloudNativePG cluster.
It works with Volto or the Classic UI, and with any routing.

## Prerequisites

* A PostgreSQL server reachable from the cluster, with a database and a user for Plone

It doesn't need the CloudNativePG operator.

## Install

Create a secret with the credentials:

```shell
kubectl create namespace plone
kubectl create secret generic plonedb --namespace plone \
    --from-literal=database-name='plone' \
    --from-literal=database-user='plone' \
    --from-literal=database-password='<password>'
```

and install the chart, pointing it to the server:

```shell
helm install plone plone/plone --namespace plone \
    --set postgresql.enabled=false \
    --set storage.relstorage.host=db.example.com \
    --set storage.relstorage.secret.name=plonedb \
    --set routing.hostname=plone.example.com \
    --set routing.gateway.name=<gateway> \
    --set routing.gateway.namespace=<gateway-namespace>
```

Replace `<gateway>` and `<gateway-namespace>` with the name and namespace of the Gateway that serves the site, and `plone.example.com` with its hostname.
If your secret uses other keys, for example one created by another tool, set them too:

```shell
--set storage.relstorage.secret.keys.database=dbname \
--set storage.relstorage.secret.keys.user=username \
--set storage.relstorage.secret.keys.password=password
```

## How it works

With `postgresql.enabled` set to `false`, the chart doesn't create a PostgreSQL cluster.
The backend connects to `storage.relstorage.host`, with the credentials from the `storage.relstorage.secret.name` secret.
RelStorage creates its tables in the database on the first start.
