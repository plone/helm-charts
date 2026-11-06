# How to serve the site over HTTPS

This guide shows you how to serve the site over HTTPS.
By default, the site is served over HTTP, and the chart doesn't need any certificate.

TLS is terminated by the Gateway or the ingress controller, not by Plone.
So serving the site over HTTPS needs a certificate for its hostname, in a Kubernetes TLS secret, used by:

* with Gateway API: an HTTPS listener of the Gateway, which references the secret in its `certificateRefs`.
  The Gateway is managed outside of this chart.
* with ingress-nginx: the Ingress resources of the chart, with `routing.ingressNginx.tls`.

The certificate can come from cert-manager, which issues and renews certificates, for example from Let's Encrypt.
cert-manager isn't required: any TLS secret works, and some cloud load balancers terminate TLS themselves.

## Tell Plone that the site uses HTTPS

Once the site is served over HTTPS, set `routing.https` to `true`, so that Plone generates `https://` URLs.
Setting it doesn't create a certificate or configure TLS.
If the site doesn't use the default port, set `routing.port` as well.

## Use the HTTPS listener of a Gateway

Attach the route to the HTTPS listener of the Gateway:

```shell
helm install plone plone/plone --namespace plone --create-namespace \
    --set routing.hostname=plone.example.com \
    --set routing.https=true \
    --set routing.gateway.name=<gateway> \
    --set routing.gateway.namespace=<gateway-namespace> \
    --set routing.gateway.sectionName=https
```

For the Gateway options, see [How to attach the site to a Gateway](attach-to-gateway.md).

## Use TLS with ingress-nginx

With ingress-nginx and cert-manager, which issues the certificate into the `plone-tls` secret:

```shell
helm install plone plone/plone --namespace plone --create-namespace \
    --set routing.type=ingress-nginx \
    --set routing.hostname=plone.example.com \
    --set routing.https=true \
    --set routing.ingressNginx.tls[0].secretName=plone-tls \
    --set routing.ingressNginx.tls[0].hosts[0]=plone.example.com \
    --set 'routing.ingressNginx.annotations.cert-manager\.io/cluster-issuer=letsencrypt-prod'
```

Replace `letsencrypt-prod` with the name of your cluster issuer.
