# No routing

Don't create any routing resources, for example to write your own routing, or to try the chart with `kubectl port-forward`.
It works with any of the other scenarios.

## Prerequisites

* The prerequisites of the scenario it's combined with, except Gateway API

## Install

```shell
helm install plone plone/plone --namespace plone --create-namespace \
    --set routing.type=none
```

Combine these values with the ones of any other scenario, for example `--set frontend.enabled=false` for the Classic UI.

To try the site, forward a local port to the frontend, or to the backend with the Classic UI:

```shell
kubectl port-forward --namespace plone service/plone-frontend 3000:3000
```

and open http://localhost:3000.

## Writing your own routing

Your routing must send:

* with Volto:
  * `/++api++` requests to the `<release>-backend` service on port 8080, rewritten to `/VirtualHostBase/<scheme>/<hostname>:<port>/<site id>/++api++/VirtualHostRoot/...`
  * all other requests to the `<release>-frontend` service on port 3000
* with the Classic UI: all requests to the backend, rewritten to `/VirtualHostBase/<scheme>/<hostname>:<port>/<site id>/VirtualHostRoot/...`
* with Varnish: all the requests, rewritten as above, to the `<release>-varnish` service on port 6081, instead of the backend and the frontend

For example, with the hostname `plone.example.com` over HTTPS and the default site id, `/++api++/news` becomes `/VirtualHostBase/https/plone.example.com:443/Plone/++api++/VirtualHostRoot/news`.
