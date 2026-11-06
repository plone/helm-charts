# How to configure the Plone site

This guide shows you how to choose the id, add-on profiles, and language of the Plone site that the chart creates.
It also shows you how to create the site yourself.

## Set the site values at install time

Set the values under `site` when you install the chart:

```yaml
site:
  id: Plone
  profiles: ""
  defaultLanguage: "en"
```

* `site.id` is the id of the site object in Zope.
  The site id is also used in the virtual host paths of the routing, and in the API URL of the frontend.
* `site.profiles` lists add-on profiles to apply when the site is created, comma separated.
* `site.defaultLanguage` sets the language of the site, such as `en` or `pt-br`.

These values only apply when the site is created.
Changing them later has no effect on an existing site.

## Give the site creation more time

With `site.create`, the `<release>-site` Job creates the site after each install and upgrade, if it doesn't exist yet.
Helm waits for the Job, and fails if it doesn't finish in time.
On a slow cluster, increase the `--timeout` of `helm install` and `helm upgrade`, 5 minutes by default:

```shell
helm install plone plone/plone --namespace plone --create-namespace --timeout 15m
```

Helm keeps the Job when it fails, so you can read its logs:

```shell
kubectl logs --namespace <namespace> job/<release>-site
```

## Create the site yourself

To create the site yourself, set `site.create` to `false`.
Also set it to `false` if you delete or rename the site, otherwise the next upgrade creates it again.
Then forward a local port to the backend, and open the Zope root:

```shell
kubectl port-forward --namespace <namespace> service/<release>-backend 8080:8080
```

For the type of site that the Job creates, see [Site creation](../reference/backend.md#site-creation).
