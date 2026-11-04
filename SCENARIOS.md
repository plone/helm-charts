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

The database is provided by a PostgreSQL cluster managed by the CloudNativePG operator, with one instance by default.
The operator creates the PersistentVolumeClaims to store the data, and the credentials secret.

The `plone-backend` pods connect to the primary PostgreSQL instance through the cluster's read-write service.

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

## Scenario 3: Plone with Volto using PostgreSQL, Varnish, and Gateway API
Plone with Volto using PostgreSQL, Varnish, and Gateway API is the same as scenario 2, with a Varnish cache in front of the `plone-backend` pods, and routing done with Gateway API.

### Infrastructure
Additional to scenario 2 this scenario needs `varnish` pods.
`varnish` will be provided as a StatefulSet with at least two replicas, balancing the requests between the `plone-backend` pods.

Instead of a reverse proxy pod, the routing is done by a Gateway API HTTPRoute, which any conformant Gateway API implementation supports.
It routes the `/++api++` requests to the `varnish` pods, rewriting their path for the Zope virtual host monster, and all other requests to the `plone-frontend` pods.
Clusters that still run the retired ingress-nginx controller can use Ingress resources with ingress-nginx annotations instead.

