# How-to guides

How-to guides show you how to solve a specific task.
Each one assumes you know what you want, and shows you the steps.

## Prepare the cluster

::::{grid} 1 1 2 2
:gutter: 3

:::{grid-item-card} 🐘 Install the CloudNativePG operator
:link: install-cloudnativepg
:link-type: doc

Install the operator that runs the PostgreSQL cluster of the chart.
:::

:::{grid-item-card} 🚦 Enable the Gateway API provider of Traefik
:link: enable-traefik-gateway-api
:link-type: doc

Turn on Gateway API in the Traefik of k3s or Rancher Desktop.
:::

:::{grid-item-card} 🔗 Attach the site to a Gateway
:link: attach-to-gateway
:link-type: doc

Point the HTTPRoute of the chart at the Gateway that serves the site.
:::

:::{grid-item-card} 🔒 Serve the site over HTTPS
:link: enable-https
:link-type: doc

Terminate TLS at the Gateway or the ingress controller.
:::

::::

## Choose an installation

::::{grid} 1 1 2 2
:gutter: 3

:::{grid-item-card} 🌐 Volto with PostgreSQL
:link: install-volto-postgresql
:link-type: doc

The default: Volto, RelStorage on a CloudNativePG cluster, and Gateway API.
:::

:::{grid-item-card} ⚡ Volto with PostgreSQL and Varnish
:link: install-volto-postgresql-varnish
:link-type: doc

The default, with Varnish caching the pages, the API, and the assets.
:::

:::{grid-item-card} 🗄️ Volto with ZEO
:link: install-volto-zeo
:link-type: doc

Volto, with a ZEO server deployed by the chart.
:::

:::{grid-item-card} 🏛️ Classic UI with PostgreSQL
:link: install-classic-postgresql
:link-type: doc

The Classic UI, rendered by the backend, on RelStorage.
:::

:::{grid-item-card} 🏛️ Classic UI with ZEO
:link: install-classic-zeo
:link-type: doc

The Classic UI, with a ZEO server deployed by the chart.
:::

:::{grid-item-card} 🔌 Use an external PostgreSQL server
:link: use-external-postgresql
:link-type: doc

Connect RelStorage to a PostgreSQL server that the chart doesn't manage.
:::

:::{grid-item-card} 🔌 Use an external ZEO server
:link: use-external-zeo
:link-type: doc

Connect the backend to a ZEO server that the chart doesn't deploy.
:::

:::{grid-item-card} 🧭 Route the site with ingress-nginx
:link: use-ingress-nginx
:link-type: doc

Create Ingress resources, for clusters that still run ingress-nginx.
:::

:::{grid-item-card} 🚫 Run Plone without routing
:link: run-without-routing
:link-type: doc

Skip the routing resources, and bring your own.
:::

:::{grid-item-card} 📦 Use your own images
:link: use-custom-images
:link-type: doc

Run your own backend and frontend images, and set environment variables.
:::

::::

## Configure the site and the database

::::{grid} 1 1 2 2
:gutter: 3

:::{grid-item-card} ⚙️ Configure the Plone site
:link: configure-the-site
:link-type: doc

Set the site id, the add-on profiles, and the default language.
:::

:::{grid-item-card} 🔑 Change the admin password
:link: change-admin-password
:link-type: doc

Replace the default password of the `admin` user.
:::

:::{grid-item-card} 🐘 Configure the PostgreSQL cluster
:link: configure-postgresql
:link-type: doc

Size, replicate, and back up the CloudNativePG cluster.
:::

:::{grid-item-card} 🧹 Pack the database
:link: pack-the-database
:link-type: doc

Schedule the pack job, and keep the history you need for undo.
:::

::::

## Scale and cache

::::{grid} 1 1 2 2
:gutter: 3

:::{grid-item-card} 📈 Scale and make the site highly available
:link: scale-and-high-availability
:link-type: doc

Run more replicas, with disruption budgets.
:::

:::{grid-item-card} ⚡ Cache the site with Varnish
:link: cache-with-varnish
:link-type: doc

Put Varnish in front of the backend and the frontend.
:::

:::{grid-item-card} ✏️ Customize the Varnish VCL
:link: customize-varnish-vcl
:link-type: doc

Change how Varnish routes and caches the requests.
:::

::::

## Upgrade

::::{grid} 1 1 2 2
:gutter: 3

:::{grid-item-card} 🚚 Migrate from the previous charts
:link: migrate-from-previous-charts
:link-type: doc

Move an installation of the previous charts to this one.
:::

::::

```{toctree}
:hidden: true

install-cloudnativepg
enable-traefik-gateway-api
attach-to-gateway
enable-https
install-volto-postgresql
install-volto-postgresql-varnish
install-volto-zeo
install-classic-postgresql
install-classic-zeo
use-external-postgresql
use-external-zeo
use-ingress-nginx
run-without-routing
use-custom-images
configure-the-site
change-admin-password
configure-postgresql
pack-the-database
scale-and-high-availability
cache-with-varnish
customize-varnish-vcl
migrate-from-previous-charts
```
