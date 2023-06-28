# Plone ZEO Chart

This chart deploys a [ZEO Server](https://zodb.org/en/latest/articles/old-guide/zeo.html) for [Plone](https://plone.org/).

## Configuration

The following table lists the configurable parameters of the Plone ZEO chart and their default values.

| Parameter               | Description                           | Default           |
| ----------------------- | ------------------------------------- | ----------------- |
| `replicaCount`          | Number of ZEO instances to deploy      | `1`               |
| `image.repository`      | ZEO image repository                   | `plone/plone-zeo` |
| `image.pullPolicy`      | ZEO image pull policy                  | `IfNotPresent`    |
| `image.tag`             | ZEO image tag                          | `""`              |
| `imagePullSecrets`      | ZEO image pull secrets                 | `[]`              |
| `nameOverride`          | Override the chart name                | `""`              |
| `fullnameOverride`      | Override the fully qualified app name  | `""`              |
| `serviceAccount.create` | Specifies whether to create a service account | `false`  |
| `serviceAccount.annotations` | Annotations to add to the service account | `{}`         |
| `serviceAccount.name`   | Name of the service account to use      | `""`              |
| `podAnnotations`        | Annotations to add to the pods         | `{}`              |
| `podSecurityContext`    | Security context for the pods          | `{}`              |
| `securityContext`       | Security context for the containers    | `{}`              |
| `service.type`          | Service type                           | `ClusterIP`       |
| `service.port`          | Service port                           | `8100`            |
| `resources.requests.cpu`    | CPU resource requests              | `50m`             |
| `resources.requests.memory` | Memory resource requests           | `48Mi`            |
| `persistence.enabled`   | Enable persistence for ZEO instances   | `true`            |
| `persistence.accessMode`| Access mode for the persistence volume | `ReadWriteOnce`   |
| `persistence.size`      | Size of the persistence volume          | `5Gi`             |
| `nodeSelector`          | Node selectors for pod assignment      | `{}`              |
| `tolerations`           | Tolerations for pod assignment         | `[]`              |
| `affinity`              | Affinity settings for pod assignment   | `{}`              |
