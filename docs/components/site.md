# Site

```yaml
site:
  id: Plone
  create: true
  profiles: ""
  defaultLanguage: ""
```

With `site.create`, the `<release>-site` Job creates a Plone site with the id `site.id`, if it doesn't exist yet.
It's a Helm hook that runs after each install and upgrade of the chart, so the backend pods only serve the site, and they don't go through the site creation of the `plone-backend` image, which isn't meant for production.
Helm waits for the Job, and fails if it doesn't finish in time: on a slow cluster, increase the `--timeout` of `helm install`, 5 minutes by default.
Helm deletes the Job when it succeeds, and keeps it when it fails, so you can read its logs.
The type of the site follows `frontend.enabled`: a Volto site with the frontend, a Classic UI site without it.
`site.profiles` lists add-on profiles to apply when creating the site, comma separated, and `site.defaultLanguage` sets its language, such as `en` or `pt-br`.
These values only apply when the site is created, and changing them later has no effect on an existing site.

To create the site yourself, set `site.create` to `false`, and use `kubectl port-forward` to the backend to open the Zope root.
Also set it to `false` if you delete or rename the site, otherwise the next upgrade creates it again.

The site id is also used in the virtual host paths of the routing, and in the API URL of the frontend.

## Admin user

The `plone-backend` image comes with a Zope `admin` user with the password `admin`.
Change it before exposing the site:

1. Forward a local port to the backend:

   ```shell
   kubectl port-forward --namespace <namespace> service/<release>-backend 8080:8080
   ```

2. Open http://localhost:8080/acl_users/manage_main, log in as `admin`, select the `admin` user, and change its password.
