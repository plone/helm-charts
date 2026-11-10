# How to customize the Varnish VCL

This guide shows you how to replace the default VCL of Varnish with your own, for example to apply the caching rules of [`plone.app.caching`](https://pypi.org/project/plone.app.caching/).

## Start from the default VCL

Copy the default VCL from [Varnish](../reference/varnish.md#default-vcl), and keep its backends.
The VCL goes in `varnish.vcl`, in a values file that you pass with `--values`:

```yaml
varnish:
  enabled: true
  vcl: |
    vcl 4.1;

    backend plone {
        .host = "{{ include "plone.fullname" . }}-backend";
        .port = "{{ .Values.backend.service.port }}";
    }
    # ...
```

## Keep the backends

Your VCL must keep the two backends of the default VCL, `plone` and `volto`, which point to the `<release>-backend` and `<release>-frontend` Services.
Without the Volto frontend, keep only the `plone` backend, as the default VCL does.

Keep their hosts and ports as in the default VCL, which builds them with the `plone.fullname` template, and reads the ports from `backend.service.port` and `frontend.service.port`.

## Know what the VCL can read

The chart renders the VCL as a template, with its own values.
It can use the templates of the chart, such as `plone.fullname`, and all its values, such as `frontend.enabled` or `routing.hostname`.

## Apply the change

Run `helm upgrade` with the values file.
The chart updates the ConfigMap `<release>-varnish-vcl`, and the change of `varnish.vcl` rolls out the Varnish pods, which read the new VCL when they start.

When you only change values that your VCL reads, and not `varnish.vcl` itself, Varnish keeps the VCL that it read when it started.
Restart it:

```shell
kubectl rollout restart --namespace <namespace> deployment/<release>-varnish
```

For the other options of the `varnish-cache` chart, set them under `varnish`.
See its [documentation](https://github.com/varnish/helm-varnish).
