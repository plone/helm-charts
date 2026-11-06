# Varnish

With `varnish.enabled` set to `true`, the chart installs Varnish with the [`varnish-cache` chart](https://github.com/varnish/helm-varnish-cache) of Varnish Software, and routes all the requests of the site through it.

## Resources

| Resource | Name | Details |
|---|---|---|
| Deployment | `<release>-varnish` | 1 replica by default, `varnish.server.replicas` |
| Service | `<release>-varnish` | ClusterIP, port 6081 |
| ConfigMap | `<release>-varnish-vcl` | the rendered VCL |
| ServiceAccount | `<release>-varnish` | |
| PodDisruptionBudget | `<release>-varnish` | only when `varnish.server.pdb.enabled` is `true` |

The resources of Varnish are created by the `varnish-cache` chart, which the values under `varnish` configure.

## Affinity

The `varnish-cache` chart requires each Varnish pod to run on a different node.
This chart sets `varnish.server.affinity` to a preference instead, so that the pods spread over the nodes when there are several, while Varnish can still roll out on a cluster with one node.

## Default VCL

The VCL is set in `varnish.server.vclConfig`.
It is a Helm template, rendered by the `varnish-cache` chart, with its own values.
The default VCL is:

```text
vcl 4.1;

# The Plone backend: the API requests with Volto, all requests with the
# Classic UI.
backend plone {
    .host = "{{ include "plone.vcl.fullname" . }}-backend";
    .port = "{{ .Values.global.plone.backendPort }}";
}
{{- if .Values.ploneFrontend }}

# The Volto frontend: the pages and static assets of the site.
backend volto {
    .host = "{{ include "plone.vcl.fullname" . }}-frontend";
    .port = "{{ .Values.global.plone.frontendPort }}";
}
{{- end }}

sub vcl_recv {
    {{- if .Values.ploneFrontend }}
    # The routing rewrites the API requests to Zope virtual host paths.
    if (req.url ~ "^/VirtualHostBase/") {
        set req.backend_hint = plone;
    } else {
        set req.backend_hint = volto;
        # The static assets of Volto don't depend on cookies, which
        # would prevent caching them.
        if (req.url ~ "^/static/") {
            unset req.http.Cookie;
        }
    }
    {{- else }}
    set req.backend_hint = plone;
    {{- end }}
}
```

The default VCL:

* sends the requests to the `<release>-backend` and `<release>-frontend` Services.
  These Services balance the connections of Varnish between their pods, and only send them to the pods that are ready, so the VCL doesn't depend on the number of pods.
* removes the cookies of the requests for the static assets of Volto (`/static/`), which don't depend on them, so that Varnish can cache them.
* otherwise follows the built-in VCL of Varnish.
  Requests with cookies or authorization, such as the ones of logged-in users, aren't cached.
  The responses are cached according to their `Cache-Control` headers, for 120 seconds without them.

Kubernetes balances per connection, not per request.
Varnish keeps a pool of connections to each Service, which spreads the load between the pods.

## The frontend setting

The default VCL can't read the values of this chart, such as `frontend.enabled`, because it's rendered by the `varnish-cache` chart, with its own values.
`varnish.ploneFrontend` must match `frontend.enabled`.
The chart fails with an explanation when they don't match and Varnish is enabled.

## The Services in global values

For the same reason, the VCL gets the names and ports of the Services from `global.plone`, the only values that the two charts share:

| Global value | Must match | Default |
|---|---|---|
| `global.plone.fullnameOverride` | `fullnameOverride` | `""` |
| `global.plone.backendPort` | `backend.service.port` | `8080` |
| `global.plone.frontendPort` | `frontend.service.port` | `3000` |

The `plone.vcl.fullname` template builds the prefix of the Service names from `global.plone.fullnameOverride`, as the chart does from `fullnameOverride`.
With `varnish.enabled`, the chart fails with an explanation when a global value doesn't match the value it mirrors.

## Custom VCL rules

A custom VCL replaces `varnish.server.vclConfig`.
It is rendered as a template by the `varnish-cache` chart, so it can use `.Release.Name`, the values under `varnish`, and the values under `global`, but not the other values of this chart.
The `varnish-cache` chart restarts the Varnish pods when the VCL changes.

All the options of the `varnish-cache` chart are set under `varnish`, see its [documentation](https://github.com/varnish/helm-varnish-cache).
For how to write a custom VCL, see [How to customize the Varnish VCL](../how-to/customize-varnish-vcl.md).
