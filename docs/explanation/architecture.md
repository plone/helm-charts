# About the architecture of the chart

The chart installs Plone 6 as a set of components, which a few values combine in several ways.
This page explains how a request reaches Plone, and why the components are shaped the way they are.
For the components themselves, see the [reference](../reference/index.md).

## One chart, several configurations

The default configuration is Volto, RelStorage on PostgreSQL, and Gateway API routing.
Each of the other choices is a value: the user interface, the storage, the database, the cache, and the routing.
The [scenarios](../how-to/install-volto-postgresql.md) show the combinations that the chart tests on every change.

The chart checks the combinations of values before it installs anything.
A combination that can't work, such as ZEO with a PostgreSQL cluster, fails with an explanation.
This keeps a mistake in the values from becoming a half-working installation.

## The request flow with Volto

With Volto, the routing splits the requests in two:

* the `/++api++` requests go to the backend, which serves the REST API and stores the content
* everything else goes to the frontend, which renders the pages and serves the static assets

The frontend renders the pages of the site on the server, and in the browser.
When it renders a page on the server, it calls the backend straight through the backend service, not through the public address of the site.
The browser calls the backend through the `/++api++` route, the same way as any API client.

The backend reads and writes the database, which is PostgreSQL with RelStorage, or the ZEO server.
With Varnish enabled, both kinds of requests pass through Varnish first, which may answer them from its cache.

## The request flow with the Classic UI

Without the frontend, every request goes to the backend, which renders the site itself.
The routing rewrites the requests to the Zope virtual host path of the site, as it does for the API of Volto.
See [The Zope virtual host rewrite](virtual-host-rewrite.md) for what the rewrite does.

## Why Varnish sits in front

Varnish keeps the responses that it can reuse, so that the backend and the frontend serve fewer requests.
Its VCL decides where each request goes, by looking at the path, and the path carries the routing decision: the requests that the routing rewrote to a virtual host path go to the backend.

Kubernetes balances the connections, not the requests, between the pods of a Service.
Varnish keeps a pool of connections to each Service, so that the requests spread over the pods of the backend and the frontend.

The chart prefers to spread the Varnish pods over the nodes.
The `varnish-cache` chart requires it, which blocks rolling updates of Varnish on a cluster with one node.
This chart only prefers it, so that Varnish can roll out on any cluster, and still spreads its pods when there are several nodes.

## Why the backend is a Deployment

The backend doesn't keep its data on the pod.
With RelStorage, the objects and the blobs are in the database, and each pod only keeps a cache.
With ZEO, the data is in the ZEO server.
A new pod starts with empty caches, and fills them as it serves requests.

So the backend pods are interchangeable, and the chart runs them as a Deployment.
A rollout starts a new pod, and waits for it to be ready, before it stops an old one, so even a single backend pod is replaced without interrupting the site.
`backend.updateStrategy` sets this behavior.

Up to version 0.3 of the chart, the backend was a StatefulSet.
A StatefulSet stops a pod before it starts its replacement, so every upgrade interrupted a site with one backend pod.
Nothing used the stable pod names that a StatefulSet gives: Varnish and the routing address the backend Service.

### What a rolling update costs

**Old and new code overlap.**
For a few seconds, from the moment the new pod is ready until the old pod stops, both run against the same database.
Several backend pods sharing a database is the normal way to run Plone, so the overlap itself is safe.
The risk is narrower: an object that the new code writes, with a class that the old code doesn't have, can fail to load in the old pod until it stops.
The chart doesn't run the upgrade steps of Plone or of add-ons, which you run from the control panel after the rollout, when only the new code is serving.
So the overlap only matters when a release asks you to stop all the clients before you start the new code, such as for a change of the database schema.
For such an upgrade, set `backend.updateStrategy` to `{type: Recreate}`: Kubernetes stops all the pods before it starts the new ones, and the site is down in between.

**Room for one more pod.**
With `maxSurge: 1`, each rollout needs room for one more backend pod, with its requests, and one more connection to PostgreSQL or the ZEO server.
When the namespace quota or the nodes have no room for it, the new pod stays `Pending`, the old pods keep serving, and the rollout doesn't progress.
`helm upgrade` reports success anyway, unless you run it with `--wait`.

**No volume per pod.**
A Deployment can't give each pod its own PersistentVolumeClaim, as `volumeClaimTemplates` of a StatefulSet do, and a `ReadWriteOnce` volume shared by the old and new pod would block the rollout.
The backend doesn't need one: `/data` only holds caches, which a new pod fills again as it serves requests.
Keeping the blob cache or the ZEO client cache across restarts would need such volumes, and so a StatefulSet again.

### Stopping a pod without failing requests

When a pod stops, it leaves the endpoints of its Service, and Kubernetes sends it `SIGTERM`.
Both happen at the same time, so for a moment Varnish, the Gateway, or the ingress controller can still send requests to a pod that is shutting down, and these requests fail.
The backend and frontend pods first sleep for `preStopSleepSeconds`, 5 seconds by default, while they still serve the requests that reach them, and only then get `SIGTERM`.
`terminationGracePeriodSeconds`, 30 seconds by default, covers the sleep and the shutdown.

## Why the database needs packing

The ZODB keeps the old revisions of the objects, which is what makes undo possible.
Over time, these revisions take more space, and the pack job removes the ones you no longer need.
The `pack.days` value sets how much history the job keeps, 7 days by default.
For the trade-off between undo and space, see [Storage choices](storage-choices.md#packing).
