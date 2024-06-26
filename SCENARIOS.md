# Deployment scenarios with Kubernetes

If you don't see your scenario in this document, we would welcome a pull request.

We identified different scenarios for deploying Plone with Kubernetes.
This is not meant to be complete, but should work for 80% of the use cases.
Other use cases can build on top of these scenarios.

The scenarious are written from simple to complex and build on top of each other.

## Scenario 1: Plone Classic UI using PostgreSQL
Plone Classic UI with PostgreSQL is the simplest scenario.
It uses a database, stores the blobs in the database, and uses Classic UI, which is provided by the `plone-backend` container.
The image is used as-is, without any additional add-ons.

### Infrastructure
`plone-backend` will be provided as a Deployment with at least two replicas.
A LoadBalancer service bundles the `plone-backend` pods.

The database is provided by a PostgreSQL StatefulSet with one replica.
It needs a PersistentVolumeClaim to store the data.

The `plone-backend` pods connect to the PostgreSQL pod.

## Scenario 2: Plone with Volto using PostgreSQL and Routing capable Ingress
Plone with Volto using PostgreSQL is the next step.
Volto is the default Plone 6 frontend.
This scenario is the minimal default setup for a modern Plone 6 site in Kubernetes with a routing-capable ingress controller.
It uses a PostgreSQL database and stores the blobs in the database.
It provides the Plone backend API server, which is run by the `plone-backend` image.
The Volto frontend is provided by the `plone-frontend` image.
Both images are used as-is, without any additional add-ons.

### Infrastructure
Additional to scenario 1, this scenario needs a `plone-frontend` pod.
`plone-frontend` will be provided as a Deployment with at least two replicas.
A LoadBalancer service bundles the `plone-frontend` pods.

Also, it needs an ingress with HTTP routing capabilities, such as a Traefik ingress controller.
Kubernetes environments without such an ingress controller are covered by scenario 3.
The ingress controller will be configured to route the requests to the `plone-frontend` and `plone-backend` pods, dependent on the requests path.

## Scenario 2: Plone with Volto using PostgreSQL and Non-Routing capable Ingress
Plone with Volto using PostgreSQL and Non-Routing capable Ingress is the same as scenario 2, but without the need for a routing-capable ingress controller.

### Infrastructure
Additional to scenario 2 this scenario needs an `nginx` pod.
The `nginx` pod will be configured to route the requests to the `plone-frontend` and `plone-backend` pods, depending on the requests path.
`nginx` will be provided as a Deployment with at least two replicas.
A LoadBalancer service bundles the `nginx` pods.

