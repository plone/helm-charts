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

The database name, the user name, and the password can have any character: the chart passes them to the PostgreSQL client library in environment variables, outside the connection string.

To require an encrypted connection, set `storage.relstorage.sslmode`, for example to `require`, or to `verify-full` to also check the certificate of the server against a trusted authority:

```shell
--set storage.relstorage.sslmode=require
```

The values are the ones of the [`sslmode` of libpq](https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-PROTECTION).
Without it, the client uses SSL if the server offers it, without checking the certificate.

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

This scenario, with a CloudNativePG cluster outside the chart, is tested by [`ci/external-postgresql-values.yaml`](../../charts/plone/ci/external-postgresql-values.yaml).
