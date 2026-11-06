# Frontend

The frontend runs the [`plone-frontend` image](https://6.docs.plone.org/install/containers/images/frontend.html), the Volto frontend of Plone 6.
With `frontend.enabled` set to `false`, the chart creates no frontend resources, and the backend serves the Classic UI.

## Resources

| Resource | Name | Created when |
|---|---|---|
| Deployment | `<release>-frontend` | `frontend.enabled` is `true` |
| Service | `<release>-frontend`, port 3000, port name `http` | `frontend.enabled` is `true` |
| PodDisruptionBudget | `<release>-frontend` | `frontend.enabled` is `true`, `frontend.replicas` is more than 1, and `frontend.podDisruptionBudget.enabled` is `true` |

## Image

| Value | Default |
|---|---|
| `frontend.image.repository` | `docker.io/plone/plone-frontend` |
| `frontend.image.tag` | `19.7.0` |
| `frontend.image.pullPolicy` | `IfNotPresent` |

## Environment variables

The chart sets `RAZZLE_INTERNAL_API_PATH` to `http://<release>-backend:<backend.service.port>/<site.id>`.
The frontend uses it for the calls of server-side rendering, which go straight to the backend service, not through Varnish.
The browsers call the backend through the `/++api++` route instead, see [Routing](routing.md).

The `frontend.env` list adds more variables, see the [`plone-frontend` image documentation](https://6.docs.plone.org/install/containers/images/frontend.html).

## Probes

| Probe | Request | Period |
|---|---|---|
| Readiness | `GET /ok` on `http` | 10 seconds |
| Liveness | `GET /ok` on `http` | 10 seconds |

## Values

The values of this component are under `frontend`, see [Values](values.md#frontend).
The resource requests default to `50m` of CPU and `200Mi` of memory.
Its pod options are `podAnnotations`, `podSecurityContext`, `securityContext`, `nodeSelector`, `tolerations`, and `affinity`.
