# Backend

The backend runs the [`plone-backend` image](https://6.docs.plone.org/install/containers/images/backend.html).
It serves the REST API for the Volto frontend, or the whole site with the Classic UI.

## Resources

| Resource | Name | Created when |
|---|---|---|
| Deployment | `<release>-backend` | always |
| Service | `<release>-backend`, port 8080, port name `http` | always |
| PodDisruptionBudget | `<release>-backend` | `backend.replicas` is more than 1, and `backend.podDisruptionBudget.enabled` is `true` |
| Secret | `<release>-admin`, key `password` | `site.admin.existingSecret` is empty |

A rollout starts a new pod, and waits for it to be ready, before it stops an old one: `backend.updateStrategy` is a `RollingUpdate` with `maxSurge: 1` and `maxUnavailable: 0`.
See [Why the backend is a Deployment](../explanation/architecture.md#why-the-backend-is-a-deployment).

## Image

| Value | Default |
|---|---|
| `backend.image.repository` | `docker.io/plone/plone-backend` |
| `backend.image.tag` | the `appVersion` of the chart, `6.2.2` |
| `backend.image.pullPolicy` | `IfNotPresent` |

## Environment variables

The chart sets these variables on the backend container:

| Variable | Value |
|---|---|
| `ZODB_CACHE_SIZE` | `backend.zodbCacheSize` |

It sets these ones on the site Job, see [Site creation](#site-creation):

| Variable | Value | Set when |
|---|---|---|
| `SITE_ID` | `site.id` | always |
| `TYPE` | `volto` with the frontend, `classic` without it | always |
| `PROFILES` | `site.profiles` | `site.profiles` isn't empty |
| `SITE_DEFAULT_LANGUAGE` | `site.defaultLanguage` | `site.defaultLanguage` isn't empty |

The backend container and the site Job both get the storage variables, which depend on `storage.type`.
With RelStorage, the chart sets `DBHOST`, `DBPORT`, `DBNAME`, `DBUSER`, `DBPASSWORD`, `RELSTORAGE_DSN`, `RELSTORAGE_KEEP_HISTORY`, and `RELSTORAGE_BLOB_CACHE_SIZE`.
With ZEO, it sets `ZEO_ADDRESS` and `ZEO_CLIENT_CACHE_SIZE`.
See [Storage](storage.md).

The `backend.env` list adds more variables to both, after the ones above.

## Probes

| Probe | Request | Period | Timeout | Failure threshold |
|---|---|---|---|---|
| Startup | `GET /ok` on `http` | 10 seconds | 5 seconds | 60, so up to 10 minutes for the first start |
| Readiness | `GET /ok` on `http` | 10 seconds | 5 seconds | 3 |
| Liveness | TCP connection to `http` | 10 seconds | 5 seconds | 6 |

`/ok` is the health check of the `plone-backend` image: a view of the Zope root that returns `OK` without rendering a page, so it stays cheap on a busy site.
The liveness probe restarts a pod only when Zope no longer accepts connections, as a busy pod, or one waiting for a slow database, can be slow to answer HTTP requests.

## Site creation

With `site.create` set to `true` (default), the chart creates the Job `<release>-site`, which creates the Plone site with the id `site.id`, if it doesn't exist yet.

| Setting | Value |
|---|---|
| Hook | `post-install,post-upgrade`, so Helm waits for it after each install and upgrade |
| Deletion | before a new run, and when it succeeds; a failed Job is kept for its logs |
| Retries | 6 |
| Image | the backend image |
| Site type | Volto with `frontend.enabled`, Classic UI without it |

The backend pods only serve the site, and don't go through the site creation of the `plone-backend` image, which isn't meant for production.
`site.profiles` and `site.defaultLanguage` only apply when the site is created.

## Admin password

The chart sets the password of the `admin` user of the Zope root, from the Secret `site.admin.existingSecret`, or the Secret `<release>-admin` that the chart generates.

| Setting | Value |
|---|---|
| Job | `<release>-admin`, a Helm hook after each install and upgrade, after the site Job, runs `files/set-admin-password.py` from the ConfigMap `<release>-admin` |
| Init container | `admin-password`, with the backend image, writes `admin:<password>` to the `admin` volume, in the backend pods and the site Job |
| `admin` volume | `emptyDir` in memory, mounted at `/app/inituser`, the `inituser` file of Zope |
| Generated password | 32 random letters and digits, kept on upgrades |
| Password rules | not empty, no colon, no space at the start or the end; the init container fails otherwise |

At each start, while the Zope root has its own user folder, Zope replaces the `admin` user with the one of `inituser`, so that a new database never accepts the password `admin`.
Creating a Plone site replaces that user folder with a PluggableAuthService, which ignores `inituser`.
From then on, the Job sets the password, in the `users` plugin of the Zope root: it creates the `admin` user if it doesn't exist, and doesn't change the other users.
See [How to change the admin password](../how-to/change-admin-password.md).

## Volume

The backend mounts an `emptyDir` volume at `/data`, for the client home, the blob cache, and the ZEO client cache.
The content of an `emptyDir` is lost when its pod is replaced.

## Values

The values of this component are under `backend`, see [Values](values.md#backend).
Its pod options are `podAnnotations`, `podSecurityContext`, `securityContext`, `nodeSelector`, `tolerations`, and `affinity`.
