# How to migrate from the previous charts

This guide shows you which values replace the previous charts of this repository, and how to move a site to this chart.
This chart replaces the charts that were previously in this repository.

## Map the previous charts to values

| Previous chart | Values |
|---|---|
| `plone6-volto-pg` | defaults |
| `plone6-volto-pg-varnish` (formerly `plone6-volto-pg-nginx-varnish`) | `varnish.enabled: true` |
| `plone6-volto-zeo`, and the previous `plone` chart | `storage.type: zeo`, `postgresql.enabled: false` |
| `plone6-classic-pg` | `frontend.enabled: false` |
| `plone6-classic-nodb` | `frontend.enabled: false`, `postgresql.enabled: false`, and `storage.relstorage` pointing to your database |
| `backend`, `frontend`, `zeoserver`, `nginx`, `varnish`, `postgresql` subcharts | not needed anymore, they are part of this chart or replaced by community charts |

## Install as a new release

The resource names and values have changed.
Install this chart as a new release, and move the data, rather than upgrading a release of a previous chart.

## Route with Gateway API

The Traefik IngressRoute of `plone6-volto-pg` is replaced by the Gateway API routing, which Traefik supports.
To attach the route to your Gateway, see [How to attach the site to a Gateway](attach-to-gateway.md).
