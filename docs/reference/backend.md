# Backend

The backend runs the [`plone-backend` image](https://6.docs.plone.org/install/containers/images/backend.html).
It serves the REST API for the Volto frontend, or the whole site with the Classic UI.

## Resources

| Resource | Name | Created when |
|---|---|---|
| StatefulSet | `<release>-backend` | always |
| Service | `<release>-backend`, port 8080, port name `http` | always |
| Headless service | `<release>-backend-director`, port 8080 | always |
| PodDisruptionBudget | `<release>-backend` | `backend.replicas` is more than 1, and `backend.podDisruptionBudget.enabled` is `true` |
| Secret | `<release>-admin`, key `password` | `site.admin.existingSecret` is empty |

The headless service is the governing service that StatefulSets require.
It gives each pod a stable DNS name, `<release>-backend-<n>.<release>-backend-director`.

## Image

| Value | Default |
|---|---|
| `backend.image.repository` | `docker.io/plone/plone-backend` |
| `backend.image.tag` | the `appVersion` of the chart, `6.2.2` |
| `backend.image.pullPolicy` | `IfNotPresent` |

## Environment variables

The chart sets these variables on the backend container:

| Variable | Value | Set when |
|---|---|---|
| `SITE` | `site.id` | `site.create` is `true` |
| `TYPE` | `volto` with the frontend, `classic` without it | `site.create` is `true` |
| `PROFILES` | `site.profiles` | `site.create` is `true`, and `site.profiles` isn't empty |
| `SITE_DEFAULT_LANGUAGE` | `site.defaultLanguage` | `site.create` is `true`, and `site.defaultLanguage` isn't empty |
| `ZODB_CACHE_SIZE` | `backend.zodbCacheSize` | always |

The storage variables depend on `storage.type`.
With RelStorage, the chart sets `DBHOST`, `DBPORT`, `DBNAME`, `DBUSER`, `DBPASSWORD`, `RELSTORAGE_DSN`, `RELSTORAGE_KEEP_HISTORY`, and `RELSTORAGE_BLOB_CACHE_SIZE`.
With ZEO, it sets `ZEO_ADDRESS` and `ZEO_CLIENT_CACHE_SIZE`.
See [Storage](storage.md).

The `backend.env` list adds more variables, after the ones above.

## Probes

| Probe | Request | Period | Timeout | Failure threshold |
|---|---|---|---|---|
| Startup | `GET /` on `http` | 10 seconds | 15 seconds | 60, so up to 10 minutes for the first start |
| Readiness | `GET /` on `http` | 10 seconds | 15 seconds | 3 |
| Liveness | `GET /` on `http` | 10 seconds | 15 seconds | 3 |

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

The backend pods and the site Job set the password of the `admin` user of the Zope root, from the Secret `site.admin.existingSecret`, or the Secret `<release>-admin` that the chart generates.

| Setting | Value |
|---|---|
| Init container | `admin-password`, with the backend image, writes `admin:<password>` to the `admin` volume |
| `admin` volume | `emptyDir` in memory, mounted at `/app/inituser`, the `inituser` file of Zope |
| Generated password | 32 random letters and digits, kept on upgrades |
| Password rules | not empty, no colon, no space at the start or the end; the init container fails otherwise |

At each start, while the Zope root has no other user, Zope replaces the `admin` user with the one of `inituser`.
See [How to change the admin password](../how-to/change-admin-password.md).

## Volume

The backend mounts an `emptyDir` volume at `/data`, for the client home, the blob cache, and the ZEO client cache.
The content of an `emptyDir` is lost when its pod is replaced.

## Values

The values of this component are under `backend`, see [Values](values.md#backend).
Its pod options are `podAnnotations`, `podSecurityContext`, `securityContext`, `nodeSelector`, `tolerations`, and `affinity`.
