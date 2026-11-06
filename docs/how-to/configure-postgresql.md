# How to configure the PostgreSQL cluster

This guide shows you how to change the PostgreSQL cluster that the chart creates for the default scenario.
The cluster is managed by the CloudNativePG `cluster` chart, and all its options can be set under the `postgresql` key.

## Run more instances

To run three instances with automatic failover:

```yaml
postgresql:
  cluster:
    instances: 3
    enablePDB: true
```

For what the instances mean for availability, see [How to scale and make the site highly available](scale-and-high-availability.md).

## Change the storage size

The cluster gets an 8Gi volume by default.
Change it with `postgresql.cluster.storage.size`, see [Values](../reference/values.md#postgresql).

## Connect through a connection pooler

To connect Plone through a connection pooler, set `storage.relstorage.host` to the service of the pooler.

## Backups, monitoring, and recovery

The `cluster` chart documents the options for backups, monitoring, connection pooling, and recovery.
See the [`cluster` chart documentation](https://github.com/cloudnative-pg/charts/tree/main/charts/cluster).
