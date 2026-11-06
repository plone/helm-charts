# Varnish

With `varnish.enabled`, the chart installs Varnish with the [`varnish-cache` chart](https://github.com/varnish/helm-varnish-cache) of Varnish Software, and routes all the requests of the site through it.
The default configuration runs one Varnish replica, as the `<release>-varnish` Deployment, behind the `<release>-varnish` `ClusterIP` service on port 6081.
See [Replicas and high availability](high-availability.md) to run more.

The `varnish-cache` chart requires each Varnish pod to run on a different node, which blocks the rolling updates of Varnish on clusters with no spare node, such as single-node clusters: the new pod can't start while the old one runs, and the old VCL stays in use.
This chart overrides `varnish.server.affinity` to only prefer it, so that the pods still spread over the nodes when there are several.

## Requests

With Volto, Varnish caches both the backend and the frontend:

* `/++api++` requests: Gateway or ingress controller → Varnish → backend pods
* everything else, the pages and the static assets of the site: Gateway or ingress controller → Varnish → frontend pods

The routing rewrites the `/++api++` requests to Zope virtual host paths, starting with `/VirtualHostBase/`, before they reach Varnish, and the VCL sends these paths to the backend, and all others to the frontend.

With the Classic UI, all requests go through Varnish to the backend.

## VCL

The VCL is set in `varnish.server.vclConfig`.
The default VCL:

* sends the requests to the `<release>-backend` and `<release>-frontend` Services, which balance the connections of Varnish between their pods, and only send them to the pods that are ready, so the VCL doesn't depend on the number of pods
* removes the cookies of the requests for the static assets of Volto (`/static/`), which don't depend on them, so that Varnish can cache them
* otherwise follows the built-in VCL of Varnish: it doesn't cache the requests with cookies or authorization, such as the ones of logged-in users, and caches the responses according to their `Cache-Control` headers, for 120 seconds without them

Kubernetes balances per connection, not per request, but Varnish keeps a pool of connections to each Service, which spreads the load between the pods.

The default VCL can't read the values of this chart, such as `frontend.enabled`, because it's rendered by the `varnish-cache` chart, with its own values.
So, with the Classic UI, also set `varnish.ploneFrontend` to `false`, and the VCL only uses the backend:

```shell
helm install plone plone/plone --namespace plone --create-namespace \
    --set frontend.enabled=false \
    --set varnish.enabled=true \
    --set varnish.ploneFrontend=false \
    --set routing.hostname=plone.example.com \
    --set routing.gateway.name=<gateway> \
    --set routing.gateway.namespace=<gateway-namespace>
```

The chart fails with an explanation when `varnish.ploneFrontend` doesn't match `frontend.enabled`.

For the same reason, the VCL gets the Services from the global values, the only ones that the two charts share.
If you change `fullnameOverride`, `backend.service.port`, or `frontend.service.port`, set the same value in `global.plone`:

```yaml
fullnameOverride: web
backend:
  service:
    port: 80
frontend:
  service:
    port: 81
global:
  plone:
    fullnameOverride: web
    backendPort: 80
    frontendPort: 81
```

The chart fails with an explanation when they don't match.

## Custom VCL

To customize the caching, for example for the caching rules of [plone.app.caching](https://pypi.org/project/plone.app.caching/), replace `varnish.server.vclConfig` with your own VCL in a values file, keeping the backends of the default VCL.
It's rendered as a template by the `varnish-cache` chart, with its own values, so it can use `.Release.Name`, the values under `varnish`, and the values under `global`, but not the other values of this chart.
The `varnish-cache` chart restarts the Varnish pods when the VCL changes.

All the options of the `varnish-cache` chart can be set under `varnish`, see its [documentation](https://github.com/varnish/helm-varnish-cache).
