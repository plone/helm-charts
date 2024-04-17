# Install Plone 6 with RelStorage/PostgreSQL, Volto, and optional Traefik IngressRoute

This Helm chart combines the PostgreSQL, backend, and frontend subcharts to install Plone 6 with RelStorage/PostgreSQL as the database backend, Volto frontend, and an optional Traefik IngressRoute.

## Prerequisites

The PostgreSQL subchart expects a Persistent Volume Claim with a default name of `db-pvc` for the database (PGDATA) directory.
Override the default in `values.yaml` with:

```yaml
postgresql:
  persistentVolumeClaim:
    claimName: <your-pvc>
```

The optional IngressRoute will only work with Traefik Ingress Controller.
Let's Encrypt is used as the certificate authority when TLS is enabled, and needs to be properly configured in your cluster.

## Options and defaults

### PostgreSQL

### Backend

### Volto

### Ingress
