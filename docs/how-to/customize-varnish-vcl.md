# How to customize the Varnish VCL

This guide shows you how to replace the default VCL of Varnish with your own, for example to apply the caching rules of [plone.app.caching](https://pypi.org/project/plone.app.caching/).

## Start from the default VCL

Copy the default VCL from [Varnish](../reference/varnish.md#default-vcl), and keep its backends.
The VCL goes in `varnish.server.vclConfig`, in a values file that you pass with `--values`.

## Keep the backends

Your VCL must keep the two backends of the default VCL, `plone` and `volto`, which point to the `<release>-backend` and `<release>-frontend` Services.
Without the Volto frontend, keep only the `plone` backend, as the default VCL does.

Keep their hosts and ports as in the default VCL, which reads them from `global.plone`.

## Know what the VCL can read

The VCL is rendered as a template by the `varnish-cache` chart, with its own values.
It can use `.Release.Name`, the values under `varnish`, and the values under `global`, but not the other values of this chart.

## Apply the change

Run `helm upgrade` with the values file.
The `varnish-cache` chart restarts the Varnish pods when the VCL changes.

For the other options of the `varnish-cache` chart, set them under `varnish`.
See its [documentation](https://github.com/varnish/helm-varnish-cache).
