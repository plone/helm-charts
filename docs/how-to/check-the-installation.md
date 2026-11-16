# How to check an installation with `helm test`

This guide shows you how to check that an installed release serves the site, with the checks that come with the chart.
They run in a pod, and check that:

* the home page answers with an HTML page;
* the site has its public URL: the REST API returns it as the `@id` of the site with Volto, and the page has it in `data-portal-url` with the Classic UI;
* the `admin` user logs in with the password of its Secret;
* the `admin` user can't log in with the password `admin`;
* with Varnish, a second request for the home page is a cache hit.

The CI of the chart runs the same checks after it installs each scenario.

## Run the checks

Once the pods are ready, run:

```shell
helm test plone --namespace plone --logs
```

Replace `plone` with the name and the namespace of your release.
Each check prints a line, and the command fails if one of them fails:

```text
Checking http://localhost: page http://plone-frontend:3000/, API http://plone-backend:8080/VirtualHostBase/http/localhost:80/Plone/++api++/VirtualHostRoot
ok   Home page: HTML page
ok   API returns the public URL: @id http://localhost
ok   admin login: with the password of the Secret
ok   admin login with the password admin: refused
4 of 4 checks passed
```

The pod `<release>-test` stays after the checks, so that you can read its logs again with `kubectl logs`.
The next `helm test` replaces it.

`helm uninstall` doesn't remove the pod and its ConfigMap, because they are Helm test hooks.
Remove them after you uninstall the release:

```shell
kubectl delete pod,configmap --namespace plone \
    -l app.kubernetes.io/instance=plone,app.kubernetes.io/component=test
```

## Check the routing too

By default, the checks send their requests to the Services of the chart, with the paths that the routing would use, so they don't check the Gateway or the ingress controller.
To check them too, set `tests.url` to the address of the Gateway or the ingress controller inside the cluster.
The requests carry the hostname of `routing.hostname` in their `Host` header, as a browser would.

The checks only send plain HTTP, and don't follow redirects.
Use an address that serves the site over HTTP.
When the Gateway or the ingress controller redirects HTTP to HTTPS, such as with `routing.https`, the checks stop with a message that names the redirect.
In that case, leave `tests.url` empty, to check the Services of the chart instead.

For the Traefik of k3s, whose Gateway is set up by [How to enable the Gateway API provider of Traefik on k3s](enable-traefik-gateway-api.md):

```yaml
tests:
  url: http://traefik.kube-system.svc.cluster.local
```

For the ingress-nginx controller:

```yaml
tests:
  url: http://ingress-nginx-controller.ingress-nginx.svc.cluster.local
```

## Wait longer for the site

The checks wait up to 120 seconds for the home page to answer, as the routing may take a moment to pick up a new route.
To wait longer, set `tests.timeout`, in seconds.

## Turn the checks off

Set `tests.enabled` to `false` to leave the test pod and its ConfigMap out of the release.
