# Plone 6 Helm Chart

This Helm chart deploys Plone 6 backend and frontend components in a Kubernetes cluster.

## Backend Configuration

The default values for the backend component are as follows:

| Parameter                           | Value                    |
| ----------------------------------- | ------------------------ |
| `backend.image.repository`          | plone/plone-backend      |
| `backend.image.pullPolicy`          | IfNotPresent             |
| `backend.image.tag`                 | (defaults to AppVersion) |
| `backend.image.replicaCount`        | 1                        |
| `backend.service.type`              | ClusterIP                |
| `backend.service.port`              | 8080                     |
| `backend.resources.requests.cpu`    | 100m                     |
| `backend.resources.requests.memory` | 280Mi                    |

See `values.yaml` file for other configuration values.

## Frontend Configuration

The default values for the frontend component are as follows:

| Parameter                            | Value                |
| ------------------------------------ | -------------------- |
| `frontend.image.repository`          | plone/plone-frontend |
| `frontend.image.pullPolicy`          | IfNotPresent         |
| `frontend.image.tag`                 | 16.21.2              |
| `frontend.replicaCount`              | 1                    |
| `frontend.service.type`              | ClusterIP            |
| `frontend.service.port`              | 3000                 |
| `frontend.resources.requests.cpu`    | 50m                  |
| `frontend.resources.requests.memory` | 192Mi                |

See `values.yaml` file for other configuration values.

## Ingress Configuration

This chart implements external access to the Plone 6 installation via Ingress and implements `/++api++/` rewrites if using the Nginx Ingress Controller.

### Default Values

The default values for the ingress configuration are as follows:

| Parameter                            | Value                  |
| ------------------------------------ | ---------------------- |
| `ingress.enabled`                    | true                   |
| `ingress.className`                  | ""                     |
| `ingress.annotations`                |                        |
| `ingress.hosts`                      |                        |
| `ingress.hosts[0].host`              | chart-example.local    |
| `ingress.hosts[0].paths`             |                        |
| `ingress.hosts[0].paths[0].path`     | /                      |
| `ingress.hosts[0].paths[0].pathType` | ImplementationSpecific |
| `ingress.tls`                        | []                     |
| `apiIngress.enabled`                 | true                   |
| `apiIngress.annotations`             | true                   |

See `values.yaml` file for other configuration values.

## Zeoserver Configuration

The Zeoserver component is responsible for the Plone CMS ZEO server.

### Default Values

The default values for the Zeoserver configuration are as follows:

| Parameter                       | Value |
| ------------------------------- | ----- |
| `zeoserver.enabled`             | true  |
| `zeoserver.persistence.enabled` | true  |

For more ZEO related values, see the ZEO Server Helm chart.