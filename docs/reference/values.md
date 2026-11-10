# Values

This page describes the values of the chart.
The defaults are the ones of [`charts/plone/values.yaml`](../../charts/plone/values.yaml), written as YAML.
Values that aren't set by default are marked as not set.

## Top-level values

| Key | Default | Description |
|---|---|---|
| `nameOverride` | `""` | Overrides the chart name in the labels of the resources. |
| `fullnameOverride` | `""` | Overrides the prefix of the resource names, which is the release name by default. |
| `imagePullSecrets` | `[]` | Pull secrets of all the pods. |
| `serviceAccount.create` | `true` | Creates the ServiceAccount `<release>` for the pods of the chart. |
| `serviceAccount.name` | `""` | Name of the ServiceAccount. Defaults to `<release>` when the chart creates it, and to the `default` ServiceAccount of the namespace otherwise. |
| `serviceAccount.annotations` | `{}` | Annotations of the ServiceAccount. |
| `serviceAccount.automountServiceAccountToken` | `false` | Mounts the token of the ServiceAccount in the pods. Plone doesn't use the Kubernetes API. |

## `site`

| Key | Default | Description |
|---|---|---|
| `site.id` | `"Plone"` | Id of the Plone site object in Zope. |
| `site.create` | `true` | Creates the site, if it doesn't exist yet, with a Job that runs after each install and upgrade. Its type follows `frontend.enabled`. |
| `site.profiles` | `""` | Add-on profiles to apply when creating the site, comma separated. |
| `site.defaultLanguage` | `""` | Default language of the site, such as `en` or `pt-br`. |
| `site.admin.existingSecret` | `""` | Secret with the password of the `admin` user of the Zope root. Empty generates a random password into the Secret `<release>-admin`, kept on upgrades. See [How to change the admin password](../how-to/change-admin-password.md). |
| `site.admin.passwordKey` | `"password"` | Key of the password in `site.admin.existingSecret`. |

## `storage`

| Key | Default | Description |
|---|---|---|
| `storage.type` | `"relstorage"` | `relstorage` for RelStorage on PostgreSQL, or `zeo` for a ZEO server. |

### `storage.relstorage`

| Key | Default | Description |
|---|---|---|
| `storage.relstorage.host` | `""` | PostgreSQL host. Defaults to `<release>-postgresql-rw` with `postgresql.enabled`, and is required without it. |
| `storage.relstorage.port` | `5432` | PostgreSQL port. |
| `storage.relstorage.secret.name` | `""` | Secret with the database name, user name, and password. Defaults to `<release>-postgresql-app` with `postgresql.enabled`, and is required without it. |
| `storage.relstorage.secret.keys` | `{}` | Keys of the database name (`database`), user name (`user`), and password (`password`) in the secret. Not set by default, see [Storage](storage.md#relstorage). |
| `storage.relstorage.sslmode` | `""` | SSL mode of the connection, such as `require` or `verify-full`, see the [libpq documentation](https://www.postgresql.org/docs/current/libpq-ssl.html). Empty uses the default of libpq, `prefer`. |
| `storage.relstorage.keepHistory` | `true` | Keeps the history of the objects, needed for undo. |
| `storage.relstorage.blobCacheSize` | `"100mb"` | Size of the blob cache of each backend pod. |

### `storage.zeo`

| Key | Default | Description |
|---|---|---|
| `storage.zeo.address` | `""` | `host:port` of an external ZEO server. Empty deploys a ZEO server with the chart. |
| `storage.zeo.clientCacheSize` | `"128MB"` | Size of the ZEO client cache of each backend pod. |

### `storage.zeo.server`

| Key | Default | Description |
|---|---|---|
| `storage.zeo.server.image.repository` | `"docker.io/plone/plone-zeo"` | Image of the ZEO server. |
| `storage.zeo.server.image.tag` | `"6.0.0"` | Tag of the ZEO server image. |
| `storage.zeo.server.image.pullPolicy` | `"IfNotPresent"` | Pull policy of the ZEO server image. |
| `storage.zeo.server.persistence.enabled` | `true` | Stores the data of the ZEO server in a persistent volume. |
| `storage.zeo.server.persistence.accessMode` | `"ReadWriteOnce"` | Access mode of the volume. |
| `storage.zeo.server.persistence.size` | `"5Gi"` | Size of the volume. |
| `storage.zeo.server.persistence.storageClass` | not set | Storage class of the volume. Unset uses the default class, and `-` sets an empty class name. |
| `storage.zeo.server.env` | `[]` | Extra environment variables of the ZEO server, see the [`plone-zeo` image documentation](https://6.docs.plone.org/install/containers/images/zeo.html). |
| `storage.zeo.server.resources` | `{requests: {cpu: "50m", memory: "48Mi"}}` | Resources of the ZEO server. |
| `storage.zeo.server.podAnnotations` | `{}` | Annotations of the ZEO server pod. |
| `storage.zeo.server.podSecurityContext` | `{runAsNonRoot: true, runAsUser: 500, runAsGroup: 500, fsGroup: 500, fsGroupChangePolicy: OnRootMismatch, seccompProfile: {type: RuntimeDefault}}` | Pod security context of the ZEO server pod. The defaults comply with the Pod Security `restricted` profile. |
| `storage.zeo.server.securityContext` | `{allowPrivilegeEscalation: false, capabilities: {drop: [ALL]}}` | Security context of the ZEO server container. |
| `storage.zeo.server.nodeSelector` | `{}` | Node selector of the ZEO server pod. |
| `storage.zeo.server.tolerations` | `[]` | Tolerations of the ZEO server pod. |
| `storage.zeo.server.affinity` | `{}` | Affinity of the ZEO server pod. |

## `pack`

| Key | Default | Description |
|---|---|---|
| `pack.enabled` | `true` | Creates the CronJob that packs the database. |
| `pack.schedule` | `"15 3 * * *"` | Cron schedule of the pack job, every night at 03:15. |
| `pack.timeZone` | `""` | Time zone of the schedule, such as `Europe/Berlin`. Empty uses the time zone of the Kubernetes controller manager, usually UTC. |
| `pack.days` | `7` | Keeps the history of the last days, so that undo works for them. `0` removes all of the history. |
| `pack.backoffLimit` | `1` | Retries of a failed pack, until the next schedule. |
| `pack.activeDeadlineSeconds` | `82800` | Stops a pack that runs for longer, 23 hours by default. Keep it below the schedule interval. |
| `pack.resources` | `{}` | Resources of the pack job. |
| `pack.env` | `[]` | Extra environment variables of the pack job, after the ones of `backend.env`. |
| `pack.nodeSelector` | `{}` | Node selector of the pack pods. Empty uses `backend.nodeSelector`. |
| `pack.tolerations` | `[]` | Tolerations of the pack pods. Empty uses `backend.tolerations`. |
| `pack.affinity` | `{}` | Affinity of the pack pods. Empty uses `backend.affinity`. |

## `tests`

The checks run by `helm test`, see [How to check an installation with `helm test`](../how-to/check-the-installation.md).

| Key | Default | Description |
|---|---|---|
| `tests.enabled` | `true` | Creates the test pod and its ConfigMap, run by `helm test`. |
| `tests.url` | `""` | URL to send the requests to, such as the address of the Gateway or the ingress controller inside the cluster, to check the routing too. Empty sends them to the Services of the chart. |
| `tests.timeout` | `120` | Seconds to wait for the home page to answer before the checks. |
| `tests.resources` | `{}` | Resources of the test pod. |

## `backend`

| Key | Default | Description |
|---|---|---|
| `backend.image.repository` | `"docker.io/plone/plone-backend"` | Image of the backend. |
| `backend.image.tag` | `""` | Tag of the backend image. Empty uses the `appVersion` of the chart. |
| `backend.image.pullPolicy` | `"IfNotPresent"` | Pull policy of the backend image. |
| `backend.replicas` | `1` | Number of backend pods. |
| `backend.updateStrategy` | `{type: RollingUpdate, rollingUpdate: {maxSurge: 1, maxUnavailable: 0}}` | Strategy of the backend Deployment. The default starts a new pod before it stops an old one. |
| `backend.podDisruptionBudget.enabled` | `true` | Creates a PodDisruptionBudget, when there is more than one replica. |
| `backend.podDisruptionBudget.minAvailable` | `"50%"` | Minimum number of available pods. |
| `backend.podDisruptionBudget.maxUnavailable` | not set | Maximum number of unavailable pods, as an alternative to `minAvailable`. |
| `backend.zodbCacheSize` | `50000` | Size of the ZODB object cache, in objects. |
| `backend.env` | `[]` | Extra environment variables of the backend, see the [`plone-backend` image documentation](https://6.docs.plone.org/install/containers/images/backend.html). |
| `backend.service.type` | `"ClusterIP"` | Type of the backend service. |
| `backend.service.port` | `8080` | Port of the backend service. |
| `backend.resources` | `{requests: {cpu: "100m", memory: "300Mi"}}` | Resources of the backend pods. |
| `backend.startupProbe` | `{httpGet: {path: "/ok", port: "http"}, periodSeconds: 10, timeoutSeconds: 5, failureThreshold: 60}` | Startup probe. It allows up to 10 minutes for the first start, during which the database is initialized. |
| `backend.readinessProbe` | `{httpGet: {path: "/ok", port: "http"}, periodSeconds: 10, timeoutSeconds: 5, failureThreshold: 3}` | Readiness probe. `/ok` returns `OK` without rendering a page. |
| `backend.livenessProbe` | `{tcpSocket: {port: "http"}, periodSeconds: 10, timeoutSeconds: 5, failureThreshold: 6}` | Liveness probe: a TCP connection, so that a busy pod isn't restarted. |
| `backend.podAnnotations` | `{}` | Annotations of the backend pods. |
| `backend.podSecurityContext` | `{runAsNonRoot: true, runAsUser: 500, runAsGroup: 500, fsGroup: 500, fsGroupChangePolicy: OnRootMismatch, seccompProfile: {type: RuntimeDefault}}` | Pod security context of the backend pods, the site Job, the pack CronJob, and the `helm test` pod. The defaults comply with the Pod Security `restricted` profile. |
| `backend.securityContext` | `{allowPrivilegeEscalation: false, capabilities: {drop: [ALL]}}` | Security context of their containers. |
| `backend.nodeSelector` | `{}` | Node selector of the backend pods. |
| `backend.tolerations` | `[]` | Tolerations of the backend pods. |
| `backend.affinity` | `{}` | Affinity of the backend pods. |

## `frontend`

| Key | Default | Description |
|---|---|---|
| `frontend.enabled` | `true` | Installs the Volto frontend. Set it to `false` for the Classic UI. |
| `frontend.image.repository` | `"docker.io/plone/plone-frontend"` | Image of the frontend. |
| `frontend.image.tag` | `"19.7.0"` | Tag of the frontend image. |
| `frontend.image.pullPolicy` | `"IfNotPresent"` | Pull policy of the frontend image. |
| `frontend.replicas` | `1` | Number of frontend pods. |
| `frontend.podDisruptionBudget.enabled` | `true` | Creates a PodDisruptionBudget, when there is more than one replica. |
| `frontend.podDisruptionBudget.minAvailable` | `"50%"` | Minimum number of available pods. |
| `frontend.podDisruptionBudget.maxUnavailable` | not set | Maximum number of unavailable pods, as an alternative to `minAvailable`. |
| `frontend.env` | `[]` | Extra environment variables of the frontend, see the [`plone-frontend` image documentation](https://6.docs.plone.org/install/containers/images/frontend.html). |
| `frontend.service.type` | `"ClusterIP"` | Type of the frontend service. |
| `frontend.service.port` | `3000` | Port of the frontend service. |
| `frontend.resources` | `{requests: {cpu: "50m", memory: "200Mi"}}` | Resources of the frontend pods. |
| `frontend.startupProbe` | `{httpGet: {path: "/ok", port: "http"}, periodSeconds: 5, failureThreshold: 60}` | Startup probe. It allows up to 5 minutes for the first start. |
| `frontend.readinessProbe` | `{httpGet: {path: "/ok", port: "http"}, periodSeconds: 10}` | Readiness probe. |
| `frontend.livenessProbe` | `{httpGet: {path: "/ok", port: "http"}, periodSeconds: 10}` | Liveness probe. |
| `frontend.podAnnotations` | `{}` | Annotations of the frontend pods. |
| `frontend.podSecurityContext` | `{runAsNonRoot: true, runAsUser: 1000, runAsGroup: 1000, seccompProfile: {type: RuntimeDefault}}` | Pod security context of the frontend pods. The defaults comply with the Pod Security `restricted` profile. |
| `frontend.securityContext` | `{allowPrivilegeEscalation: false, capabilities: {drop: [ALL]}}` | Security context of the frontend container. |
| `frontend.nodeSelector` | `{}` | Node selector of the frontend pods. |
| `frontend.tolerations` | `[]` | Tolerations of the frontend pods. |
| `frontend.affinity` | `{}` | Affinity of the frontend pods. |

## `postgresql`

These values configure the PostgreSQL cluster of the CloudNativePG `cluster` chart.
The chart accepts all the other values of that chart under `postgresql` too, see its [documentation](https://github.com/cloudnative-pg/charts/tree/main/charts/cluster).

| Key | Default | Description |
|---|---|---|
| `postgresql.enabled` | `true` | Creates the PostgreSQL cluster with the chart. Set it to `false` with ZEO, or with an external PostgreSQL server. |
| `postgresql.cluster.instances` | `1` | Number of PostgreSQL instances. |
| `postgresql.cluster.enablePDB` | `false` | Creates a PodDisruptionBudget for the cluster. |
| `postgresql.cluster.enableSuperuserAccess` | `false` | Enables the superuser access of the cluster. Plone only needs the database owner created by `initdb`. |
| `postgresql.cluster.storage.size` | `"8Gi"` | Size of the volume of each instance. |
| `postgresql.cluster.initdb.database` | `"plone"` | Name of the database. |
| `postgresql.cluster.initdb.owner` | `"plone"` | Owner of the database. |

## `varnish`

These values configure the Varnish cache, which the `varnish-cache` chart installs.
The chart accepts all the other values of that chart under `varnish` too, see its [documentation](https://github.com/varnish/helm-varnish).

| Key | Default | Description |
|---|---|---|
| `varnish.enabled` | `false` | Installs Varnish in front of the site. |
| `varnish.vcl` | `""` | VCL of Varnish, rendered as a template with the values of this chart. Empty uses the default VCL. Restart Varnish after a change. See [Varnish](varnish.md#the-vcl). |
| `varnish.server.replicas` | `1` | Number of Varnish pods. |
| `varnish.server.pdb.enabled` | `false` | Creates a PodDisruptionBudget for Varnish. |
| `varnish.server.pdb.minAvailable` | `"50%"` | Minimum number of available Varnish pods. |
| `varnish.server.service.type` | `"ClusterIP"` | Type of the Varnish service. |
| `varnish.server.service.http.port` | `6081` | Port of the Varnish service. |
| `varnish.server.affinity` | a preference for pod anti-affinity by node | Affinity of the Varnish pods. See [Varnish](varnish.md#affinity). |
| `varnish.server.vclConfigPath` | `"/etc/varnish/plone/default.vcl"` | The VCL file that Varnish reads, from the ConfigMap `<release>-varnish-vcl`. |
| `varnish.server.extraVolumes` | the `plone-vcl` volume | Mounts the ConfigMap `<release>-varnish-vcl`. Keep it when you add volumes. |
| `varnish.server.extraVolumeMounts` | the `plone-vcl` mount, at `/etc/varnish/plone` | Keep it when you add mounts. |

## `routing`

| Key | Default | Description |
|---|---|---|
| `routing.type` | `"gateway"` | `gateway` for a Gateway API HTTPRoute, `ingress-nginx` for Ingress resources, or `none` for no routing resources. |
| `routing.hostname` | `"localhost"` | Public hostname of the site. |
| `routing.https` | `false` | Whether clients reach the site over HTTPS. Used to build the URLs, and doesn't configure TLS. |
| `routing.port` | `""` | Public port of the site. Empty uses 443 with HTTPS, and 80 without. |

### `routing.gateway`

| Key | Default | Description |
|---|---|---|
| `routing.gateway.name` | `""` | Gateway of the HTTPRoute. Required with `routing.type: gateway`, unless `parentRefs` is set. |
| `routing.gateway.namespace` | `""` | The namespace of the Gateway. Empty uses the namespace of the release. |
| `routing.gateway.sectionName` | `""` | Listener of the Gateway. Empty accepts all the listeners that accept the route. |
| `routing.gateway.parentRefs` | `[]` | Gateways to attach to, as Gateway API parent references. Takes precedence over `name`, `namespace`, and `sectionName`. |
| `routing.gateway.annotations` | `{}` | Annotations of the HTTPRoute. |

### `routing.ingressNginx`

| Key | Default | Description |
|---|---|---|
| `routing.ingressNginx.className` | `"nginx"` | IngressClass of the Ingress resources. |
| `routing.ingressNginx.annotations` | `{}` | Annotations added to all the Ingress resources, for example for cert-manager. |
| `routing.ingressNginx.tls` | `[]` | TLS section of the Ingress resources, with `secretName` and `hosts`. |

## Validation

The chart fails to install with an explanation when the values don't make sense together:

* `storage.type` must be `relstorage` or `zeo`.
* `routing.type` must be `gateway`, `ingress-nginx`, or `none`.
* With `varnish.enabled`, the VCL is set in `varnish.vcl`: `varnish.server.vclConfig` must be empty, and `varnish.server.vclConfigs` must not set the file of `varnish.server.vclConfigPath`.
* With `routing.type: gateway`, `routing.gateway.name` or `routing.gateway.parentRefs` must be set.
* With `postgresql.enabled` set to `false` and `storage.type: relstorage`, `storage.relstorage.host` and `storage.relstorage.secret.name` must be set.
* With `storage.type: zeo`, `postgresql.enabled` must be `false`.
