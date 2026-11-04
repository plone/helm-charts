# Backend

The backend runs the [`plone-backend` image](https://6.docs.plone.org/install/containers/images/backend.html), configured with its environment variables.
It serves the REST API for the Volto frontend, or the whole site with the Classic UI.
On its first start, it creates the Plone site, see [Site](site.md).

The chart creates:

* the `<release>-backend` StatefulSet
* the `<release>-backend` service, on port 8080
* the headless `<release>-backend-director` service
* the `<release>-backend` PodDisruptionBudget, with more than one replica

```yaml
backend:
  replicas: 1
  zodbCacheSize: 50000
  env: []
  resources:
    requests:
      cpu: 100m
      memory: 300Mi
```

`backend.env` adds environment variables to the backend, see the [`plone-backend` image documentation](https://6.docs.plone.org/install/containers/images/backend.html) for the supported ones.
The image tag defaults to the chart `appVersion`.
To run your own image with add-ons, set `backend.image.repository` and `backend.image.tag`.

The backend is a StatefulSet, with the headless `<release>-backend-director` service that StatefulSets require, so that each pod has a stable name.
Its startup probe allows 10 minutes for the first start, during which the site is created.
