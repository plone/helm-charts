# Storage

`storage.type` selects how Plone stores its database.
It accepts two values:

* `relstorage` (default): RelStorage on PostgreSQL.
  Objects and blobs are stored in the database, and each backend pod only keeps a cache.
* `zeo`: a ZEO server.
  The backend pods are its clients.

For the reasons behind the choice, see [Storage choices](../explanation/storage-choices.md).

## RelStorage

### PostgreSQL cluster

With `postgresql.enabled` set to `true` (default), the chart creates a PostgreSQL cluster with the CloudNativePG `cluster` chart, named `<release>-postgresql`.
The cluster chart creates:

| Resource | Name | Default |
|---|---|---|
| Cluster | `<release>-postgresql` | 1 instance, with an 8Gi volume |
| Database | `plone`, owned by the user `plone` | `postgresql.cluster.initdb` |
| Secret | `<release>-postgresql-app`, with the credentials of the `plone` user | created by the operator |
| Service | `<release>-postgresql-rw`, which points to the primary instance | created by the operator |

The chart connects the backend to `<release>-postgresql-rw`, with the credentials of `<release>-postgresql-app`.
The secret has the keys `dbname`, `username`, and `password`.
All the options of the cluster chart are under the `postgresql` key, see [Values](values.md#postgresql).

### External server

With `postgresql.enabled` set to `false`, the chart doesn't create a cluster.
Then `storage.relstorage.host` and `storage.relstorage.secret.name` are required.
The secret must contain the database name, user, and password under the keys set in `storage.relstorage.secret.keys`.
Without `postgresql.enabled`, these keys default to `database-name`, `database-user`, and `database-password`.

### RelStorage values

| Value | Default | Meaning |
|---|---|---|
| `storage.relstorage.host` | `""` | PostgreSQL host, defaults to `<release>-postgresql-rw` |
| `storage.relstorage.port` | `5432` | PostgreSQL port |
| `storage.relstorage.keepHistory` | `true` | Keeps the history of the objects, which undo needs |
| `storage.relstorage.blobCacheSize` | `100mb` | Size of the blob cache of each backend pod |

## ZEO

With `storage.type` set to `zeo`, and `storage.zeo.address` empty, the chart deploys a ZEO server:

| Resource | Name | Details |
|---|---|---|
| StatefulSet | `<release>-zeo` | 1 replica, the ZEO server is a single pod |
| Service | `<release>-zeo` | ClusterIP, port 8100, port name `zeo` |

The ZEO server runs the [`plone-zeo` image](https://6.docs.plone.org/install/containers/images/zeo.html).

| Value | Default |
|---|---|
| `storage.zeo.server.image.repository` | `docker.io/plone/plone-zeo` |
| `storage.zeo.server.image.tag` | `6.0.0` |
| `storage.zeo.server.persistence.enabled` | `true` |
| `storage.zeo.server.persistence.accessMode` | `ReadWriteOnce` |
| `storage.zeo.server.persistence.size` | `5Gi` |
| `storage.zeo.server.persistence.storageClass` | not set, which uses the default storage class |

With persistence enabled, the data is a volume claim template named `data` of the StatefulSet.
The volume is kept when you uninstall the chart.
Set `storageClass` to `-` for an empty storage class name.
With persistence disabled, the data is an `emptyDir` volume.

The ZEO server runs as the `plone` user of the image, with the id `500`, and `fsGroup` makes the volume writable by it.
The defaults of `storage.zeo.server.podSecurityContext` and `storage.zeo.server.securityContext` comply with the `restricted` [Pod Security Standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/).

The backend pods connect to `<release>-zeo:8100`, unless `storage.zeo.address` is set to an external server, in the form `host:port`.
`storage.zeo.clientCacheSize` (default `128MB`) sets the client cache of each backend pod.
With ZEO, `postgresql.enabled` must be `false`.

## Pack job

With `pack.enabled` set to `true` (default), the chart creates the CronJob `<release>-pack`:

| Setting | Value |
|---|---|
| Schedule | `pack.schedule`, default `15 3 * * *`, every night at 03:15 |
| Time zone | `pack.timeZone`, default the time zone of the Kubernetes controller manager, usually UTC |
| Arguments | `pack -d <pack.days>`, default `7` days of history |
| Retries | `pack.backoffLimit`, default `1` |
| Deadline | `pack.activeDeadlineSeconds`, default `82800`, 23 hours |
| Command | `zodbpack` with RelStorage, `zeopack` with ZEO |
| Image | the backend image |
| Concurrency | `Forbid`, so that two packs don't run at the same time |

The job uses the storage variables of the backend, and its `backend.env`, followed by `pack.env`.
It runs on the nodes of `pack.nodeSelector`, `pack.tolerations`, and `pack.affinity`, or of the backend when they are empty, so that it reaches the database as the backend does.
Packing removes the object revisions older than `pack.days`, so the undo of older changes is no longer possible.
Set `pack.enabled` to `false` to turn it off, for example when an external server is packed elsewhere.
For how to change the job, see [How to pack the database](../how-to/pack-the-database.md).
