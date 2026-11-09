# CloudNativePG operator

The PostgreSQL cluster is run by the CloudNativePG operator, a CNCF project, which takes care of the database pods, volumes, credentials, failover, and backups.
Install it once per Kubernetes cluster, before you install the chart.
It needs permissions to create cluster-wide resources (CustomResourceDefinitions and ClusterRoles), usually as a cluster administrator.

With Helm:

```shell
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm upgrade --install cnpg cnpg/cloudnative-pg \
    --namespace cnpg-system --create-namespace --wait
```

Or with `kubectl`, from the release manifest:

```shell
kubectl apply --server-side -f \
    https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.30/releases/cnpg-1.30.1.yaml
kubectl rollout status deployment -n cnpg-system cnpg-controller-manager
```

Check that the operator is installed with:

```shell
kubectl get crd clusters.postgresql.cnpg.io
```

To upgrade the operator later, run the same commands with a newer version.
See the [CloudNativePG installation documentation](https://cloudnative-pg.io/documentation/current/installation_upgrade/) for other methods, such as OLM, and for upgrade notes.
