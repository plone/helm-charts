# Frontend

The frontend runs the [`plone-frontend` image](https://6.docs.plone.org/install/containers/images/frontend.html), the default Volto frontend of Plone 6.

With `frontend.enabled` (default), the chart creates:

* the `<release>-frontend` Deployment
* the `<release>-frontend` service, on port 3000
* the `<release>-frontend` PodDisruptionBudget, with more than one replica

```yaml
frontend:
  enabled: true
  image:
    repository: docker.io/plone/plone-frontend
    tag: "19.6.1"
  replicas: 1
  env: []
```

Set `frontend.enabled` to `false` for the Classic UI.
To run your own Volto project, set `frontend.image.repository` and `frontend.image.tag`.
The frontend calls the backend directly for server-side rendering, through `RAZZLE_INTERNAL_API_PATH`, and the browsers call it through the `/++api++` route.
