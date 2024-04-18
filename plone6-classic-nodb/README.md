# Plone 6 Classic (no Volto) with PostgreSQL

This Helm chart installs a Plone backend, Plone 6 Classic UI for the frontend, and an optional Ingress.
It doesn't come with a database, so you need to bring your own.
RelStorage/PostgreSQL is the expected database backend.

## Prerequisites

An external database is needed for this setup to work.
The external database can be located inside or outside of your Kubernetes cluster, or the namespace you use to install this chart, as long as it is accessible.

## Options and Defaults

### Backend

### Ingress
