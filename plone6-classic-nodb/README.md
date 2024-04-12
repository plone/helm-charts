# Plone 6 Classic (no Volto) with PostgreSQL

This Helm chart combines the postgresql installs a Plone backend to use as Plone 6 Classic and optional Ingress.
It doesn't come with a database, so you need to bring your own.
RelStorage/PostgreSQL is the expected database backend.

## Prerequisites

An external database is needed for this setup to work.
The external database can be located inside or outside of your Kubernetes cluster (or the namespace you use to install this chart), it just has to be accessible.

## Options and Defaults

### Backend

### Ingress
