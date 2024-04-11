# Install Plone 6 with RelStorage/PostgreSQL, Volto and optional Traefik IngressRoute

This Helm chart combines the postgresql, backend, frontend, varnish and nginx subcharts to install Plone 6 with RelStorage/PostgreSQL as the database backend, Volto frontend, Varnish as a cache server and Nginx as a reverse proxy server.

## Prerequisites

The PostgreSQL subchart expects a Persistent Volume Claim with a default name of `db-pvc` for the database (PGDATA) directory.
Override the default in `values.yaml` with:

```yaml
postgresql:
  persistentVolumeClaim:
    claimName: <your-pvc>
```

