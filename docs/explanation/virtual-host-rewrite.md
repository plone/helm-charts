# About the Zope virtual host rewrite

Zope builds the URLs of a site from the request that it receives.
Behind the routing, the request doesn't come from the browser.
It comes from the Plone backend service, with its internal host name and port, and a path such as `/++api++/news`.
If Zope used that host name, the URLs in its responses would point to the internal service, and no browser could follow them.

The routing solves this by rewriting the path of each backend request to a Zope virtual host path:

```text
/VirtualHostBase/https/plone.example.com:443/Plone/++api++/VirtualHostRoot/news
```

The `VirtualHostBase` part tells Zope the public scheme, host name, and port of the site, and the path of the site inside the database.
The `VirtualHostRoot` part marks where the virtual root of the URL is, so that Zope builds the URLs of the response from that point.
With Volto, the root is after `/++api++`, so that the URLs in the API responses, such as `@id`, are the public URLs of the site.

## What the values must match

The public URL that the chart builds from `routing.hostname`, `routing.https`, and `routing.port` must match the URL that the browsers use.
If it doesn't, Zope generates URLs for another address, even though the requests reach the site.

The site id is part of the path, because the site is an object in the database, at the path `/Plone` by default.
The routing and the frontend both use `site.id`, so the same value must reach all of them.
Changing `site.id` after the site is created doesn't rename the site, so the paths and the site object must be changed together.

## Why Varnish sees the rewrite

When Varnish is enabled, the rewritten path reaches Varnish first.
The default VCL recognizes the `/VirtualHostBase/` prefix, and sends these requests to the backend, and the others to the frontend.
A custom VCL must keep this distinction, see [How to customize the Varnish VCL](../how-to/customize-varnish-vcl.md).

## Without the chart's routing

With `routing.type` set to `none`, the chart doesn't rewrite anything.
Your own routing must do the rewrite, with the same format.
See [How to run Plone without routing](../how-to/run-without-routing.md).
