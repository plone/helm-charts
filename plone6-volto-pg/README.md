# Install Plone 6 with RelStorage/PostgreSQL, Volto, and optional Traefik IngressRoute

This Helm chart combines the PostgreSQL, backend, and frontend subcharts to install Plone 6 with RelStorage/PostgreSQL as the database backend, Volto frontend, and an optional Traefik IngressRoute.

## Prerequisites

You need a persistent volume claim to hold the PostgreSQL database and a secret to provide the database credentials.

### Database persistent volume claim

The PostgreSQL subchart expects a Persistent Volume Claim with a default name of `db-pvc` for the database (PGDATA) directory.
Override the default in `values.yaml` with:

```yaml
postgresql:
  persistentVolumeClaim:
    claimName: <your-pvc>
```

### Database credentials

Database credentials (database name, user name, password) are expected in a secret.
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
postgresql:
  dbsecret:
    name: <your-secret>
```

See also the Kubernetes documentation [Create a Secret](https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/#create-a-secret).

The optional IngressRoute will only work with Traefik Ingress Controller.
Let's Encrypt is used as the certificate authority when TLS is enabled, and needs to be properly configured in your cluster.

## Options and defaults

### PostgreSQL

### Backend

### Volto

### Ingress
