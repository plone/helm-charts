# How to use an external PostgreSQL server

This guide shows you how to store the Plone database in a PostgreSQL server you already have, such as a managed cloud database, instead of a CloudNativePG cluster.
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

Then install the chart, pointing it to the server:

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
Replace `db.example.com` with the host of your PostgreSQL server.

The password can't contain single quotes (`'`) or backslashes (`\`).
The chart builds the connection string in the pod, wrapping the values of the secret in single quotes, and it can't escape them: a single quote makes the connection string invalid, and a backslash is dropped, so the authentication fails.
The same applies to the database and user names.

If your secret uses other keys, for example one created by another tool, add these options to the install command:

```shell
--set storage.relstorage.secret.keys.database=dbname \
--set storage.relstorage.secret.keys.user=username \
--set storage.relstorage.secret.keys.password=password
```

The keys default to `database-name`, `database-user`, and `database-password` without `postgresql.enabled`.
For all the RelStorage options, see [RelStorage values](../reference/storage.md#relstorage-values).

## How it works

With `postgresql.enabled` set to `false`, the chart doesn't create a PostgreSQL cluster.
The backend connects to `storage.relstorage.host`, with the credentials from the `storage.relstorage.secret.name` secret.
RelStorage creates its tables in the database on the first start.
