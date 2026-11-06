# Storage

`storage.type` selects how Plone stores its database:

* `relstorage` (default): RelStorage on PostgreSQL. Objects and blobs are stored in the database, and each backend pod only keeps a cache.
* `zeo`: a ZEO server. The backend pods are its clients.

## RelStorage and PostgreSQL

With `postgresql.enabled` (default), the chart creates a PostgreSQL cluster with the CloudNativePG `cluster` chart, named `<release>-postgresql`, with:

* one instance, with an 8Gi volume created by the operator
* a `plone` database, owned by the `plone` user
* a `<release>-postgresql-app` secret with the generated credentials of the `plone` user
* a `<release>-postgresql-rw` service that always points to the primary instance

The backend connects to `<release>-postgresql-rw` with the credentials from `<release>-postgresql-app`.
You don't need to create a PersistentVolumeClaim or a credentials secret.

All options of the `cluster` chart can be set under the `postgresql` key.
For example, to run three instances with automatic failover:

```yaml
postgresql:
  cluster:
    instances: 3
    enablePDB: true
```

See the [`cluster` chart documentation](https://github.com/cloudnative-pg/charts/tree/main/charts/cluster) for backups, monitoring, connection pooling, and recovery.
To connect through a connection pooler, set `storage.relstorage.host` to the service of the pooler.

Other RelStorage options:

```yaml
storage:
  relstorage:
    # Keep the history of the objects, needed for undo.
    keepHistory: true
    # Size of the blob cache of each backend pod.
    blobCacheSize: 100mb
```

To use an external PostgreSQL server, see [External PostgreSQL](../scenarios/external-postgresql.md).

## ZEO

With `storage.type: zeo` and no `storage.zeo.address`, the chart deploys a ZEO server with the [`plone-zeo` image](https://6.docs.plone.org/install/containers/images/zeo.html), as the `<release>-zeo` StatefulSet and service, on port 8100, storing its data in a 5Gi persistent volume:

```yaml
storage:
  type: zeo
  zeo:
    clientCacheSize: 128MB
    server:
      persistence:
        enabled: true
        storageClass: ""
        size: 5Gi
postgresql:
  enabled: false
```

Set `postgresql.enabled` to `false` with ZEO, so that the chart doesn't create a PostgreSQL cluster that Plone wouldn't use.
The volume is created from a volume claim template of the ZEO StatefulSet, so it's kept when you uninstall the chart.

The ZEO server runs as the `plone` user of the image, with the id 500, and `fsGroup` makes the volume writable by it.
The defaults of `storage.zeo.server.podSecurityContext` and `storage.zeo.server.securityContext` comply with the `restricted` [Pod Security Standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/).

To use an external ZEO server, see [External ZEO server](../scenarios/external-zeo.md).

## Packing

The `<release>-pack` CronJob packs the database regularly, removing old object revisions and unused objects, with `zodbpack` for RelStorage and `zeopack` for ZEO:

```yaml
pack:
  enabled: true
  schedule: "45 9 * * *"
  # Keep the history of the last days, so that undo works for them. 0 removes
  # all of the history.
  days: 7
  # Retries of a failed pack, until the next schedule.
  backoffLimit: 1
  # Stop a pack running for longer than this, 23 hours by default.
  activeDeadlineSeconds: 82800
```

Keep `pack.activeDeadlineSeconds` below the interval of `pack.schedule`, so that a stuck pack doesn't block the next one.
