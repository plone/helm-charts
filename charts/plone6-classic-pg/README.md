# Plone 6 Classic (no Volto) with PostgreSQL

This Helm chart combines the postgresql and backend to install Plone 6 with RelStorage/PostgreSQL as the database backend, a Plone backend to use as Plone 6 Classic and optional Ingress.

## Prerequisites

The PostgreSQL subchart expects a Persistent Volume Claim with a default name of `db-pvc` for the database (PGDATA) directory.
Override the default in `values.yaml` with:

```yaml
postgresql:
  persistentVolumeClaim:
    claimName: <your-pvc>
```

## Options and Defaults

### PostgreSQL

### Backend

### Volto

### Ingress
