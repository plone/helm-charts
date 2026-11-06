# Naming conventions

The chart names its resources after the release, so that several releases can run in the same namespace.
The prefix is the release name, or `fullnameOverride` when it is set.
The name of each component is the prefix, followed by the component name.

## Resource names

| Component | Name | Port |
|---|---|---|
| Backend | `<fullname>-backend` | 8080, named `http` |
| Backend director, headless | `<fullname>-backend-director` | 8080 |
| Frontend | `<fullname>-frontend` | 3000, named `http` |
| ZEO server | `<fullname>-zeo` | 8100, named `zeo` |
| Pack job | `<fullname>-pack` | |
| HTTPRoute | `<fullname>` | |
| Ingress, Volto API | `<fullname>-api` | |
| Ingress, frontend or Classic UI | `<fullname>` | |
| PostgreSQL cluster | `<fullname>-postgresql` | 5432 |
| PostgreSQL read-write service | `<fullname>-postgresql-rw` | 5432 |
| PostgreSQL credentials secret | `<fullname>-postgresql-app` | |
| Varnish | `<fullname>-varnish` | 6081 |

The names of the PostgreSQL and Varnish resources follow the conventions of their charts.
When the release name already contains the name of the dependency, the resources use the release name alone, so that the name isn't repeated.
Otherwise, the name is the release name followed by the dependency name, as in `<release>-postgresql`.

The prefix of the names of the chart resources, the release name or `fullnameOverride`, is cut at 44 characters, so that `<prefix>-backend` fits the 52 characters of a StatefulSet name, whose pods have a label with the name and a hash.

## Labels

The resources carry these labels:

| Label | Value |
|---|---|
| `helm.sh/chart` | the chart name and version |
| `app.kubernetes.io/name` | the chart name, or `nameOverride` |
| `app.kubernetes.io/instance` | the release name |
| `app.kubernetes.io/version` | the `appVersion` of the chart |
| `app.kubernetes.io/managed-by` | `Helm` |
| `app.kubernetes.io/component` | the component: `backend`, `frontend`, `zeo`, or `pack` |

The selector labels of a component are `app.kubernetes.io/name`, `app.kubernetes.io/instance`, and `app.kubernetes.io/component`.

## Virtual host paths

The Zope virtual host paths of the backend requests use the site id of `site.id`, and the public hostname, scheme, and port of the routing.
For their format, see [Routing](routing.md#virtual-host-paths).
