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

## Why the database needs packing

The ZODB keeps the old revisions of the objects, which is what makes undo possible.
Over time, these revisions take more space, and the pack job removes the ones you no longer need.
The `pack.days` value sets how much history the job keeps, 7 days by default.
For the trade-off between undo and space, see [Storage choices](storage-choices.md#packing).
