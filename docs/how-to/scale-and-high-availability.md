# How to scale and make the site highly available

This guide shows you how to run more pods of each component.
By default, each component runs a single pod: one backend, one frontend, one PostgreSQL instance, and one Varnish pod when enabled.

```yaml
backend:
  replicas: 2
frontend:
  replicas: 2
postgresql:
  cluster:
    instances: 3
    enablePDB: true
varnish:
  server:
    replicas: 2
    pdb:
      enabled: true
```

With more than one replica, the chart creates a PodDisruptionBudget for the backend and the frontend, keeping at least half of their pods running during voluntary disruptions, such as node drains.
The PodDisruptionBudget of PostgreSQL is created by the CloudNativePG operator, and the one of Varnish by its chart, so enable them as above when you run more instances.
They are disabled by default, because with a single pod they would block node drains.

The ZEO server is a single pod, and can't be replicated.
For the values, see [Values](../reference/values.md).
