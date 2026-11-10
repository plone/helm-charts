# Resources by scenario

This page lists the resources that each scenario creates, as rendered by `helm template` with the chart's values.
The names use the release name `rel` as an example, so `<release>` stands for the release name of your installation.
Resources created by the `cnpg` cluster chart and the `varnish-cache` chart are listed too, because the chart installs them.

## Resources of each component

| Resource | Created when |
|---|---|
| ServiceAccount `<release>` | `serviceAccount.create` is `true` |
| Deployment `<release>-backend` | always |
| Service `<release>-backend` | always |
| PodDisruptionBudget `<release>-backend` | `backend.replicas` is more than 1, and `backend.podDisruptionBudget.enabled` is `true` |
| Secret `<release>-admin` | `site.admin.existingSecret` is empty |
| Job and ConfigMap `<release>-admin` | always; the Job as a Helm hook after each install and upgrade, which sets the password of the `admin` user |
| Deployment `<release>-frontend` | `frontend.enabled` is `true` |
| Service `<release>-frontend` | `frontend.enabled` is `true` |
| PodDisruptionBudget `<release>-frontend` | `frontend.enabled` is `true`, `frontend.replicas` is more than 1, and `frontend.podDisruptionBudget.enabled` is `true` |
| StatefulSet `<release>-zeo` | `storage.type` is `zeo`, and `storage.zeo.address` is empty |
| Service `<release>-zeo` | `storage.type` is `zeo`, and `storage.zeo.address` is empty |
| CronJob `<release>-pack` | `pack.enabled` is `true` |
| Job `<release>-site` | `site.create` is `true`, as a Helm hook after each install and upgrade |
| HTTPRoute `<release>` | `routing.type` is `gateway` |
| Ingress `<release>-api` | `routing.type` is `ingress-nginx`, and `frontend.enabled` is `true` |
| Ingress `<release>` | `routing.type` is `ingress-nginx` |
| Cluster `<release>-postgresql` | `postgresql.enabled` is `true`, from the `cnpg` cluster chart |
| Deployment `<release>-varnish`, Service `<release>-varnish`, ServiceAccount `<release>-varnish` | `varnish.enabled` is `true`, from the `varnish-cache` chart |
| ConfigMap `<release>-varnish-vcl` | `varnish.enabled` is `true` |
| ConfigMap `<release>-test`, Pod `<release>-test` | `tests.enabled` is `true`, as Helm test hooks, created by `helm test` |

The cluster chart also renders a ConfigMap and a test Job for the PostgreSQL cluster.
The PodDisruptionBudget of PostgreSQL isn't rendered by the chart: the CloudNativePG operator creates it, when `postgresql.cluster.enablePDB` is `true`.
The PodDisruptionBudget of Varnish comes from the `varnish-cache` chart, when `varnish.server.pdb.enabled` is `true`.

## Resources of each scenario

| Resource | Default | Classic UI with ZEO | Volto with Varnish and ingress-nginx | External PostgreSQL, no routing |
|---|:---:|:---:|:---:|:---:|
| Deployment `<release>-backend` | yes | yes | yes | yes |
| Service `<release>-backend` | yes | yes | yes | yes |
| Secret `<release>-admin` | yes | yes | yes | yes |
| Job and ConfigMap `<release>-admin` | yes | yes | yes | yes |
| Deployment and Service `<release>-frontend` | yes | no | yes | yes |
| StatefulSet and Service `<release>-zeo` | no | yes | no | no |
| CronJob `<release>-pack` | yes | yes | yes | yes |
| Job `<release>-site` | yes | yes | yes | yes |
| HTTPRoute `<release>` | yes | yes | no | no |
| Ingress `<release>-api` and `<release>` | no | no | yes | no |
| Cluster `<release>-postgresql` | yes | no | yes | no |
| Varnish resources `<release>-varnish` | no | no | yes | no |

The default scenario is [Volto with PostgreSQL](../how-to/install-volto-postgresql.md), which is what the chart renders with `routing.gateway.name` set.
The Classic UI with ZEO is [How to install Plone with the Classic UI and ZEO](../how-to/install-classic-zeo.md).
The Volto scenario with Varnish and ingress-nginx is [How to install Plone with Volto, PostgreSQL, and Varnish](../how-to/install-volto-postgresql-varnish.md), with `routing.type` set to `ingress-nginx`.
The external PostgreSQL scenario is [How to use an external PostgreSQL server](../how-to/use-external-postgresql.md), with `routing.type` set to `none`.
