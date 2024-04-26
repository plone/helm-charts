# Plone 6 Classic (no Volto) with PostgreSQL

This Helm chart installs a Plone backend, Plone 6 Classic UI for the frontend, and an optional Ingress.
It doesn't come with a database, so you need to bring your own.
RelStorage/PostgreSQL is the expected database backend.

## Prerequisites

An external database is needed for this setup to work.
The external database can be located inside or outside of your Kubernetes cluster, or the namespace you use to install this chart, as long as it is accessible.

Database credentials (database name, user name, and password) are expected in a secret.
The secret name defaults to `plonedb`.

Using the `kubectl` command, you can create a secret.

```shell
kubectl create secret generic plonedb \
    --from-literal=database-name='plone' \
    --from-literal=database-user='plone' \
    --from-literal=database-password='plone'
```

You can override the default secret name in `values.yaml`:

```yaml
backend:
  dbsecret:
    name: <your-secret>
```

See also the Kubernetes documentation [Create a Secret](https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/#create-a-secret).

## Options and Defaults

### Backend

### Ingress
