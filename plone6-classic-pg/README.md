# Plone 6 Classic (no Volto) with PostgreSQL

This Helm chart combines the PostgreSQL and backend subcharts to install Plone 6 with RelStorage/PostgreSQL as the database backend, Classic UI as the frontend, and an optional Ingress.

## Prerequisites

The PostgreSQL subchart expects a Persistent Volume Claim with a default name of `db-pvc` for the database (PGDATA) directory.
Override the default in `values.yaml` with:

```yaml
postgresql:
  persistentVolumeClaim:
    claimName: <your-pvc>
```

## Options and defaults

### PostgreSQL

### Backend

### Ingress
