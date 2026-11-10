# About the community charts

The chart depends on two charts that other projects maintain.
The PostgreSQL cluster comes from the `cluster` chart of the CloudNativePG project, and the Varnish cache comes from the `varnish-cache` chart of Varnish Software.
The chart installs them as dependencies, and it configures them through the `postgresql` and `varnish` values.

## Why depend on them

CloudNativePG is an operator, which runs and repairs PostgreSQL clusters in Kubernetes.
Its maintainers know the database, the failover, and the backups better than this chart can, and they release fixes for it.
The `cluster` chart is the way the CloudNativePG project describes a cluster, so the chart doesn't need its own templates for one.

The `varnish-cache` chart is maintained by Varnish Software, the company behind Varnish.
The chart uses its Deployment and Service, and only adds the defaults that Plone needs.
It renders the VCL itself, because the `varnish-cache` chart renders templates with its own values, and the VCL needs the names and ports of the Services of this chart.

Depending on these charts means the chart does less of the work of maintaining them.
It also means the chart has to follow their conventions, for the values and for the names of their resources.

## What it means for you

The options of each dependency are available under its key, such as `postgresql.cluster.instances` and `varnish.server.replicas`.
The chart's defaults, and the names of the resources they create, follow the dependencies.
See [Naming conventions](../reference/naming.md) for the names.

The CloudNativePG operator is not part of the chart.
It must be installed in the cluster before the chart, once for the whole cluster, because it needs cluster-wide permissions.
See [How to install the CloudNativePG operator](../how-to/install-cloudnativepg.md).

The chart replaces the subcharts of the previous charts of this repository, which had their own templates for the backend, the frontend, the ZEO server, nginx, Varnish, and PostgreSQL.
See [How to migrate from the previous charts](../how-to/migrate-from-previous-charts.md).
