# Install Plone on Rancher Desktop

In this tutorial we will install Plone 6, with the Volto frontend and a PostgreSQL database, on a local Kubernetes cluster.
At the end, you will open the site in your browser.

Along the way you will install the CloudNativePG operator, enable the Gateway API routing of Traefik, and install the `plone` Helm chart.
Each step ends with a check, so you know it worked before you go on.

## Before you begin

You need:

* [Rancher Desktop](https://rancherdesktop.io) with Kubernetes enabled.
  It runs [k3s](https://k3s.io), which comes with Traefik.
* [Helm](https://helm.sh/docs/intro/install/) 3.8 or later.
* `kubectl`, the Kubernetes command line tool.

Check that the cluster responds:

```shell
kubectl get nodes
```

You should see one node, with the status `Ready`.

## Install the CloudNativePG operator

The Plone database runs in a PostgreSQL cluster, which the CloudNativePG operator manages.
Install the operator with Helm:

```shell
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm upgrade --install cnpg cnpg/cloudnative-pg \
    --namespace cnpg-system --create-namespace --wait
```

Check that the operator knows the cluster resource:

```shell
kubectl get crd clusters.postgresql.cnpg.io
```

The command prints the name of the resource.
If it reports that the resource isn't found, wait a moment, and run it again.

## Enable the Gateway API routing of Traefik

Traefik doesn't serve Gateway API routes until you enable its Gateway API provider.
Follow [How to enable the Gateway API provider of Traefik on k3s](../how-to/enable-traefik-gateway-api.md), and come back to this page when the `traefik-gateway` Gateway is programmed.

## Install Plone

Add the Plone chart repository, and install the chart with its route attached to the Gateway:

```shell
helm repo add plone https://plone.github.io/helm-charts
helm repo update
helm install plone plone/plone --namespace plone --create-namespace \
    --set routing.hostname=localhost \
    --set routing.gateway.name=traefik-gateway \
    --set routing.gateway.namespace=kube-system \
    --set routing.gateway.sectionName=web
```

The chart creates the backend, the Volto frontend, a PostgreSQL cluster, and an HTTPRoute.
Check that the Gateway accepted the route:

```shell
kubectl describe httproute plone --namespace plone
```

The `Accepted` and `ResolvedRefs` conditions show `True`.

## Wait for the pods

A Job creates the Plone site after the install, which takes a few minutes, and `helm install` waits for it.
Watch the pods until the backend, frontend, and PostgreSQL pods show `1/1` in the `READY` column.
Pods that show `Completed` have finished their job, which is normal:

```shell
kubectl get pods --namespace plone --watch
```

Press Control-C to stop watching.
To follow the creation of the site, open the log of the backend in another terminal:

```shell
kubectl logs --namespace plone plone-backend-0 --follow
```

## Open the site

Open http://localhost in your browser.
You see the Volto frontend of your new Plone site.

## Log in

The chart generated a random password for the `admin` user, into the Secret `plone-admin`.
Read it:

```shell
kubectl get secret --namespace plone plone-admin -o jsonpath='{.data.password}' | base64 -d
```

Log in to the site as `admin`, with this password.
To set a password of your own, see [How to change the admin password](../how-to/change-admin-password.md).

## Clean up

When you finish, remove the release and its namespace:

```shell
helm uninstall plone --namespace plone
kubectl delete namespace plone
```

To remove the Traefik configuration too, see [the undo steps](../how-to/enable-traefik-gateway-api.md#undo).

## Next steps

You installed Plone 6 on Kubernetes, with a database, a frontend, and a route to the site.
To learn how the parts work together, read [About the architecture of the chart](../explanation/architecture.md).
To change the installation, look in the [how-to guides](../how-to/index.md).
