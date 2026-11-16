# Varnish

With `varnish.enabled` set to `true`, the chart installs Varnish with the [`varnish-cache` chart](https://github.com/varnish/helm-varnish) of Varnish Software, and routes all the requests of the site through it.

## Resources

| Resource | Name | Details |
|---|---|---|
| Deployment | `<release>-varnish` | 1 replica by default, `varnish.server.replicas` |
| Service | `<release>-varnish` | ClusterIP, port 6081 |
| ConfigMap | `<release>-varnish-vcl` | the rendered VCL, from this chart |
| ServiceAccount | `<release>-varnish` | |
| PodDisruptionBudget | `<release>-varnish` | only when `varnish.server.pdb.enabled` is `true` |

The `varnish-cache` chart creates the resources of Varnish, which the values under `varnish` configure, except the ConfigMap of the VCL, which this chart creates.

## Affinity

The `varnish-cache` chart requires each Varnish pod to run on a different node.
This chart sets `varnish.server.affinity` to a preference instead, so that the pods spread over the nodes when there are several, while Varnish can still roll out on a cluster with one node.

## The VCL

This chart renders the VCL, with its own values, into the ConfigMap `<release>-varnish-vcl`.
The VCL is `varnish.vcl` when it is set, and the default VCL otherwise.

The Varnish pods mount the ConfigMap at `/etc/varnish/plone`, and `varnishd` reads `/etc/varnish/plone/default.vcl`.
This chart sets these `varnish-cache` values for it:

| Value | Default |
|---|---|
| `varnish.server.vclConfigPath` | `/etc/varnish/plone/default.vcl` |
| `varnish.server.extraVolumes` | the `plone-vcl` volume, from the ConfigMap `<release>-varnish-vcl` |
| `varnish.server.extraVolumeMounts` | the `plone-vcl` volume, at `/etc/varnish/plone` |

The `varnish-cache` chart renders these values with its own values, so the name of the ConfigMap only depends on the release name.
To add volumes of your own to the Varnish pods, keep the `plone-vcl` volume and its mount in the lists.

The chart fails with an explanation when `varnish.server.vclConfig` is set, or `varnish.server.vclConfigs` sets the file of `varnish.server.vclConfigPath`: the VCL is `varnish.vcl`.

### Restart after a change

Varnish reads the VCL when it starts.
The `varnish-cache` chart only restarts the Varnish pods when its own configuration changes, which doesn't include the ConfigMap of this chart.

This chart sets a default `varnish.server.podAnnotations`, which the `varnish-cache` chart renders with its own values, where `varnish.vcl` is `.Values.vcl`:

```yaml
varnish:
  server:
    podAnnotations: |
      checksum/plone-vcl: {{ .Values.vcl | sha256sum }}
```

A change of `varnish.vcl` changes the annotation, and rolls out the Varnish pods, which read the new VCL.
The annotation hashes the text of `varnish.vcl`, not the rendered VCL.
Keep the value a string, so that the `varnish-cache` chart renders it, and keep the annotation when you set annotations of your own.

A change of the values that the VCL reads doesn't restart Varnish: `frontend.enabled`, `fullnameOverride`, `backend.service.port` or `frontend.service.port` for the default VCL, and any value that your own VCL reads.
After such a change, restart Varnish:

```shell
kubectl rollout restart --namespace <namespace> deployment/<release>-varnish
```

## Default VCL

The default VCL is the `plone.varnish.defaultVcl` template of the chart:

```text
vcl 4.1;

# The Plone backend: the API requests with Volto, all requests with the
# Classic UI.
backend plone {
    .host = "{{ include "plone.fullname" . }}-backend";
    .port = "{{ .Values.backend.service.port }}";
}
{{- if .Values.frontend.enabled }}

# The Volto frontend: the pages and static assets of the site.
backend volto {
    .host = "{{ include "plone.fullname" . }}-frontend";
    .port = "{{ .Values.frontend.service.port }}";
}
{{- end }}

sub vcl_recv {
    {{- if .Values.frontend.enabled }}
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

* sends the requests to the `<release>-backend` and `<release>-frontend` Services, with the names and ports that the chart gives them.
  These Services balance the connections of Varnish between their pods, and only send them to the pods that are ready, so the VCL doesn't depend on the number of pods.
* sends all the requests to the backend with the Classic UI, when `frontend.enabled` is `false`.
* removes the cookies of the requests for the static assets of Volto (`/static/`), which don't depend on them, so that Varnish can cache them.
* otherwise follows the built-in VCL of Varnish.
  Requests with cookies or authorization, such as the ones of logged-in users, aren't cached.
  The responses are cached according to their `Cache-Control` headers, for 120 seconds without them.

Kubernetes balances per connection, not per request.
Varnish keeps a pool of connections to each Service, which spreads the load between the pods.

## Custom VCL rules

A custom VCL replaces the default VCL, in `varnish.vcl`.
It is rendered as a template with the values of this chart, so it can use the chart's templates, such as `plone.fullname`, and any of its values.

All the options of the `varnish-cache` chart are set under `varnish`, see its [documentation](https://github.com/varnish/helm-varnish).
For how to write a custom VCL, see [How to customize the Varnish VCL](../how-to/customize-varnish-vcl.md).
