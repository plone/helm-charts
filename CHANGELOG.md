# Changelog

The changes of the `plone` chart, by chart version.
Until 1.0, a minor version can have changes that need action when you upgrade: they are listed under **Breaking changes**, with what to do.

## 0.4.0 (unreleased)

### Breaking changes

- The backend is a Deployment instead of a StatefulSet, so that a rollout starts the new pod before it stops the old one, without interrupting a site with one backend pod.
  `helm upgrade` replaces the StatefulSet `<release>-backend` with a Deployment of the same name, and removes the Service `<release>-backend-director`.
  The backend pods are now named `<release>-backend-<hash>-<id>` instead of `<release>-backend-<n>`: update the scripts that use the old names, such as `kubectl logs <release>-backend-0`, to use `deployment/<release>-backend`.
  A rollout needs room for one more backend pod, and one more database connection.
  For an upgrade that asks you to stop all the clients first, set `backend.updateStrategy` to `{type: Recreate}`.
  [#37](https://github.com/plone/helm-charts/issues/37)
- The chart renders the VCL of Varnish itself, into the ConfigMap `<release>-varnish-vcl`, with its own values.
  `global.plone` and `varnish.ploneFrontend` are removed: delete them from your values.
  A custom VCL moves from `varnish.server.vclConfig` to `varnish.vcl`, where it is rendered with the values of this chart: replace `plone.vcl.fullname` with `plone.fullname`, `.Values.global.plone.backendPort` with `.Values.backend.service.port`, `.Values.global.plone.frontendPort` with `.Values.frontend.service.port`, and `.Values.ploneFrontend` with `.Values.frontend.enabled`.
  The chart fails with an explanation while `varnish.server.vclConfig` is set.
  A change of `varnish.vcl` restarts Varnish, with the annotation `checksum/plone-vcl` of the default `varnish.server.podAnnotations`: keep it if you set annotations of your own.
  After a change of the values that the VCL reads, such as `frontend.enabled` or `fullnameOverride`, restart Varnish with `kubectl rollout restart deployment/<release>-varnish`.
  [#45](https://github.com/plone/helm-charts/issues/45)

### Changed

- The `admin` user of the Zope root gets its password from a Secret: `site.admin.existingSecret`, or `<release>-admin`, which the chart generates on install and keeps on upgrades.
  The Job `<release>-admin` sets it after each install and upgrade, also on a site created by an earlier version of the chart, and creates the `admin` user if it is missing.
  On a new database, the backend pods and the site Job also write it to the `inituser` file of Zope, so that the password `admin` never works.
  After the upgrade, log in with that password: the installation notes print how to read it.
  A password changed in the Zope management interface lasts until the next install or upgrade.
  [#18](https://github.com/plone/helm-charts/issues/18)
- The backend and frontend pods sleep for 5 seconds before they stop, so that they leave the endpoints of their Service first, and the requests already sent to them don't fail.
- The chart is marked as beta, and the documentation lists what it doesn't cover yet.
  [#21](https://github.com/plone/helm-charts/issues/21)

### Added

- `site.admin.existingSecret` and `site.admin.passwordKey`.
- `backend.updateStrategy`, a `RollingUpdate` with `maxSurge: 1` and `maxUnavailable: 0` by default.
- `varnish.vcl`, a custom VCL rendered with the values of this chart.
- `backend.preStopSleepSeconds`, `backend.terminationGracePeriodSeconds`, `frontend.preStopSleepSeconds` and `frontend.terminationGracePeriodSeconds`.
- `varnish.server.podAnnotations`, with the annotation that restarts Varnish when `varnish.vcl` changes.

### Fixed

- The backend reference documented the site variables on the backend container, and as `SITE`; they are on the site Job, and the site id is `SITE_ID`.
  [#22](https://github.com/plone/helm-charts/issues/22)
- The Gateway validation message and the installation notes link to the published documentation.
  [#22](https://github.com/plone/helm-charts/issues/22)

## 0.3.0 (2026-11-09)

The first release of the single `plone` chart, with Plone 6.2.2 and Volto 19.7.0.
It replaces the charts that were previously in this repository, and covers their scenarios with values: the Volto frontend or the Classic UI, RelStorage on PostgreSQL with CloudNativePG or an external server, ZEO, an optional Varnish cache, and Gateway API, ingress-nginx, or no routing.
See [How to migrate from the previous charts](https://plone.github.io/helm-charts/how-to/migrate-from-previous-charts.html).

Earlier releases of a chart named `plone`, such as 0.1.0 in 2023, belong to those previous charts.
