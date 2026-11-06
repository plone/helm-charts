# How-to guides

How-to guides show you how to solve a specific task.
Each one assumes you know what you want, and shows you the steps.

## Prepare the cluster

* [Install the CloudNativePG operator](install-cloudnativepg.md)
* [Enable the Gateway API provider of Traefik on k3s](enable-traefik-gateway-api.md)
* [Attach the site to a Gateway](attach-to-gateway.md)
* [Serve the site over HTTPS](enable-https.md)

## Choose an installation

* [Volto with PostgreSQL](install-volto-postgresql.md), the default
* [Volto with PostgreSQL and Varnish](install-volto-postgresql-varnish.md)
* [Volto with ZEO](install-volto-zeo.md)
* [Classic UI with PostgreSQL](install-classic-postgresql.md)
* [Classic UI with ZEO](install-classic-zeo.md)
* [Use an external PostgreSQL server](use-external-postgresql.md)
* [Use an external ZEO server](use-external-zeo.md)
* [Route the site with ingress-nginx](use-ingress-nginx.md)
* [Run Plone without routing](run-without-routing.md)
* [Use your own images and environment variables](use-custom-images.md)

## Configure the site and the database

* [Configure the Plone site](configure-the-site.md)
* [Change the admin password](change-admin-password.md)
* [Configure the PostgreSQL cluster](configure-postgresql.md)
* [Pack the database](pack-the-database.md)

## Scale and cache

* [Scale and make the site highly available](scale-and-high-availability.md)
* [Cache the site with Varnish](cache-with-varnish.md)
* [Customize the Varnish VCL](customize-varnish-vcl.md)

## Upgrade

* [Migrate from the previous charts](migrate-from-previous-charts.md)
