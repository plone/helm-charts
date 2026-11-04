# Plone 6 Classic (no Volto) with PostgreSQL

This Helm chart combines the PostgreSQL and backend subcharts to install Plone 6 with RelStorage/PostgreSQL as the database backend, Classic UI as the frontend, and an optional Ingress.

## Prerequisites

The [CloudNativePG](https://cloudnative-pg.io) operator must be installed in your Kubernetes cluster.
See [Install the operator](../README.md#install-the-operator).

## Database

This chart depends on the CloudNativePG `cluster` chart, under the alias `postgresql`.
By default, it creates a single-instance PostgreSQL cluster with a `plone` database.
The operator creates the database volume and generates the credentials in the `<release>-postgresql-app` secret, which the backend uses to connect to the `<release>-postgresql-rw` service.
You don't need to create a PersistentVolumeClaim or a credentials secret.

Set the options of the `cluster` chart under the `postgresql` key, for example for high availability:

```yaml
postgresql:
  cluster:
    instances: 3
    enablePDB: true
```

To use an external database instead, set `postgresql.enabled` to `false` and configure `backend.databasehost` and `backend.dbsecret`.
See [PostgreSQL with CloudNativePG](../README.md#postgresql-with-cloudnativepg) for details.

## Options and defaults

### PostgreSQL

### Backend

### Ingress
