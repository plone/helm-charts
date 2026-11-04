# Varnish

With `varnish.enabled`, the chart installs Varnish with the [`varnish-cache` chart](https://github.com/varnish/helm-varnish-cache) of Varnish Software, and routes the backend requests through it.
The default configuration runs one Varnish replica, as the `<release>-varnish` Deployment, behind the `<release>-varnish` `ClusterIP` service on port 6081.
See [Replicas and high availability](high-availability.md) to run more.

The VCL is set in `varnish.server.vclConfig`.
The default VCL has a single backend, the `<release>-backend` Service:

```yaml
varnish:
  enabled: true
  server:
    replicas: 1
    vclConfig: |
      vcl 4.1;

      backend default {
          .host = "{{ .Release.Name }}-backend";
          .port = "8080";
      }
```

The Service balances the connections of Varnish between the backend pods, and only sends them to the pods that are ready, so the VCL doesn't depend on the number of backend pods.
Kubernetes balances per connection, not per request, but Varnish keeps a pool of connections to the backend, which spreads the load between the pods.

To customize the caching, replace `varnish.server.vclConfig` with your own VCL, keeping the backend.
It's rendered as a template by the `varnish-cache` chart, with its own values, so it can use `.Release.Name`, but not the values of this chart.
If you set `fullnameOverride`, set the backend host to `<fullnameOverride>-backend`.
The `varnish-cache` chart restarts the Varnish pods when the VCL changes.

All the options of the `varnish-cache` chart can be set under `varnish`, see its [documentation](https://github.com/varnish/helm-varnish-cache).
