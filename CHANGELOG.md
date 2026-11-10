# Changelog

The changes of the `plone` chart, by chart version.
Until 1.0, a minor version can have changes that need action when you upgrade: they are listed under **Breaking changes**, with what to do.

## 0.4.0 (unreleased)

### Breaking changes

- The backend is a Deployment instead of a StatefulSet, so that a rollout starts the new pod before it stops the old one, without interrupting a site with one backend pod.
  `helm upgrade` replaces the StatefulSet `<release>-backend` with a Deployment of the same name, and removes the Service `<release>-backend-director`.
  The backend pods are now named `<release>-backend-<hash>-<id>` instead of `<release>-backend-<n>`: update the scripts that use the old names, such as `kubectl logs <release>-backend-0`, to use `deployment/<release>-backend`.
  [#37](https://github.com/plone/helm-charts/issues/37)
- The chart renders the VCL of Varnish itself, into the ConfigMap `<release>-varnish-vcl`, with its own values.
  `global.plone` and `varnish.ploneFrontend` are removed: delete them from your values.
  A custom VCL moves from `varnish.server.vclConfig` to `varnish.vcl`, where it is rendered with the values of this chart: replace `plone.vcl.fullname` with `plone.fullname`, `.Values.global.plone.backendPort` with `.Values.backend.service.port`, `.Values.global.plone.frontendPort` with `.Values.frontend.service.port`, and `.Values.ploneFrontend` with `.Values.frontend.enabled`.
  The chart fails with an explanation while `varnish.server.vclConfig` is set.
  After a later change of the VCL, restart Varnish with `kubectl rollout restart deployment/<release>-varnish`.
  [#45](https://github.com/plone/helm-charts/issues/45)
- The backend, frontend, site Job, pack CronJob, and Varnish pods comply with the `restricted` Pod Security profile by default: they run as the user of their image, without privilege escalation or capabilities, with the `RuntimeDefault` seccomp profile.
  The backend containers run as the user `plone` (500) of the `plone-backend` image, instead of root: if you use your own image, check that it runs as this user, or set `backend.podSecurityContext` and `backend.securityContext`.
  The pods use the new ServiceAccount `<release>`, without its token.
  [#40](https://github.com/plone/helm-charts/issues/40)
- The chart validates its values with a JSON schema: an upgrade fails on a key that the chart doesn't have, such as a misspelled one, which was ignored before.
  Fix or remove it, as the error message says.
  [#36](https://github.com/plone/helm-charts/issues/36)
- The backend no longer gets `DBHOST`, `DBPORT`, `DBNAME`, `DBUSER`, and `DBPASSWORD`: if your `backend.env` refers to them, use `PGDATABASE`, `PGUSER`, and `PGPASSWORD`, see the fix of [#44](https://github.com/plone/helm-charts/issues/44) below.

### Changed

- Plone 6.2.3: the `appVersion` of the chart, and so the default tag of the backend image, is `6.2.3`.
  The backend reference explains how the images follow the chart, and how to pin an image by its digest.
  [#27](https://github.com/plone/helm-charts/issues/27)
- The `admin` user of the Zope root gets its password from a Secret: `site.admin.existingSecret`, or `<release>-admin`, which the chart generates on install and keeps on upgrades.
  The Job `<release>-admin` sets it after each install and upgrade, also on a site created by an earlier version of the chart, and creates the `admin` user if it is missing.
  On a new database, the backend pods and the site Job also write it to the `inituser` file of Zope, so that the password `admin` never works.
  After the upgrade, log in with that password: the installation notes print how to read it.
  A password changed in the Zope management interface lasts until the next install or upgrade.
  [#18](https://github.com/plone/helm-charts/issues/18)
- The chart is marked as beta, and the documentation lists what it doesn't cover yet.
  [#21](https://github.com/plone/helm-charts/issues/21)
- The maintainers in `Chart.yaml` are the active ones, fabiorauber and ericof, with links to their GitHub profiles.
  [#24](https://github.com/plone/helm-charts/issues/24)
- The startup and readiness probes of the backend request `/ok`, the health check of the `plone-backend` image, which returns `OK` without rendering a page, instead of `/`.
  The liveness probe opens a TCP connection, so that a slow database or a busy pod doesn't restart the backend pods.
  The frontend has a startup probe.
  [#39](https://github.com/plone/helm-charts/issues/39)

### Added

- `helm test` checks that the home page answers, that the site has its public URL, that the `admin` user logs in with the password of its Secret and not with `admin`, and, with Varnish, that the home page is cached.
  Set `tests.url` to the Gateway or the ingress controller to check the routing too.
  [#30](https://github.com/plone/helm-charts/issues/30)
- The CI installs Traefik with a Gateway, and the ingress-nginx controller, and runs the `helm test` checks through them for each scenario.
  [#29](https://github.com/plone/helm-charts/issues/29)
- The CI installs three more scenarios: the Classic UI on ZEO with Varnish and Gateway API, an external PostgreSQL server, and an external ZEO server.
  [#34](https://github.com/plone/helm-charts/issues/34)
- The CI upgrades a release of the last published chart, with a page and a file, to the chart of the pull request, and checks the content and the blob.
  [#32](https://github.com/plone/helm-charts/issues/32)
- A JSON schema of the values, `values.schema.json`.
  Helm refuses keys that the chart doesn't have, such as a misspelled `backend.replica`, which was ignored before, and values of the wrong type.
  The documentation CI checks that the values reference has every value, with its default.
  [#36](https://github.com/plone/helm-charts/issues/36)
- `site.admin.existingSecret` and `site.admin.passwordKey`.
- `serviceAccount.create`, `serviceAccount.name`, `serviceAccount.annotations`, and `serviceAccount.automountServiceAccountToken`.
- `frontend.startupProbe`.
- `tests.enabled`, `tests.url`, `tests.timeout`, and `tests.resources`.
- `pack.timeZone`, `pack.env`, `pack.nodeSelector`, `pack.tolerations`, and `pack.affinity`.
- `storage.relstorage.sslmode`, the SSL mode of the connection to PostgreSQL.
- `backend.updateStrategy`, a `RollingUpdate` with `maxSurge: 1` and `maxUnavailable: 0` by default.
- `varnish.vcl`, a custom VCL rendered with the values of this chart.

### Fixed

- The documentation warns that `helm uninstall` deletes the PostgreSQL cluster of the release, with its volumes and the content of the site, and the upgrade test of the CI checks it.
  [#20](https://github.com/plone/helm-charts/issues/20)
- A database name, user name, or password with a single quote or a backslash no longer breaks the connection to PostgreSQL.
  The backend gets them in `PGDATABASE`, `PGUSER`, and `PGPASSWORD`, which the PostgreSQL client reads, instead of in `RELSTORAGE_DSN`, which keeps the host and the port.
  [#44](https://github.com/plone/helm-charts/issues/44)
- The pack CronJob runs with the environment variables of `backend.env`, and on the nodes of the backend, so that it can reach the database where the backend can.
  It runs at 03:15 every night instead of 09:45, and `pack.timeZone` sets the time zone of its schedule.
  Set `pack.schedule` to keep the previous time.
  [#41](https://github.com/plone/helm-charts/issues/41)
- The backend reference documented the site variables on the backend container, and as `SITE`; they are on the site Job, and the site id is `SITE_ID`.
  [#22](https://github.com/plone/helm-charts/issues/22)
- The Gateway validation message and the installation notes link to the published documentation.
  [#22](https://github.com/plone/helm-charts/issues/22)

## 0.3.0 (2026-11-09)

The first release of the single `plone` chart, with Plone 6.2.2 and Volto 19.7.0.
It replaces the charts that were previously in this repository, and covers their scenarios with values: the Volto frontend or the Classic UI, RelStorage on PostgreSQL with CloudNativePG or an external server, ZEO, an optional Varnish cache, and Gateway API, ingress-nginx, or no routing.
See [How to migrate from the previous charts](https://plone.github.io/helm-charts/how-to/migrate-from-previous-charts.html).

Earlier releases of a chart named `plone`, such as 0.1.0 in 2023, belong to those previous charts.
