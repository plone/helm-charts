# How to run Plone with ephemeral storage

This guide shows you how to run the backend on its own FileStorage, with no ZEO server and no PostgreSQL cluster.
It suits preview and demo environments, whose image already contains the site and its example content.

> [!WARNING]
> All the content is lost on every restart and every redeploy of the backend.
> Each pod starts again from the data of its image, and the content written to it stays in that pod.
> Don't use this storage for content that you need to keep.

## Prerequisites

* An image of the backend, such as `plone/plone-backend`, whose `/data` holds the site: a FileStorage in `/data/filestorage/Data.fs`, created at build time with `create-site`.
  Without such an image, the backend starts with no site, and the site Job that would create it is skipped, so set `backend.env` with `SITE` as in the last section.
* Nothing that needs the database, such as the pack job, a backup, or a second replica.

## Install

```shell
helm install plone plone/plone --namespace preview --create-namespace \
    --set storage.type=ephemeral \
    --set postgresql.enabled=false \
    --set backend.image.repository=registry.example.org/plone-site \
    --set backend.image.tag=1.0 \
    --set routing.type=traefik \
    --set routing.hostname=preview.example.org
```

Replace the image with your own, and the routing with the one of your cluster, see [How to route the site with Traefik](use-traefik-ingress.md) or [Attach the site to a Gateway](attach-to-gateway.md).

## What the chart does

* The backend uses the FileStorage of its image, with no `ZEO_ADDRESS` and no `RELSTORAGE_DSN`.
* The backend has one replica, and its Deployment uses the `Recreate` strategy, so the old pod stops before the new one starts.
* The chart creates no site Job, no admin Job, and no pack CronJob.
  The password of the `admin` user is the one of the image.
  The Secret `<release>-admin` is still created, but it isn't applied.
* The chart mounts no volume over `/data`, so the content of the image is used.

To use an image that has no data of its own, mount an `emptyDir` over `/data` with `--set storage.ephemeral.emptyDir.enabled=true`.
The `emptyDir` keeps the content across restarts of the container, but not when the pod is deleted or moved to another node.

## Create the site at start

If the image doesn't contain the site, the backend can create it when it starts, with the `SITE` variable of the image:

```yaml
backend:
  env:
    - name: SITE
      value: Plone
```

The image creates the site on each start that finds it missing, so it is lost with the content, and it is created again on the next start.
This is how CI tests the scenario, with [`ci/ephemeral-values.yaml`](../../charts/plone/ci/ephemeral-values.yaml).

## Values that are refused

The chart fails to install with an explanation when:

* `postgresql.enabled` is `true`, which is its default: set it to `false`.
* `backend.replicas` is not `1`.

For the details of this storage type, see [Storage](../reference/storage.md#ephemeral).
