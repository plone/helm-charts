# Install Plone 6 with RelStorage/PostgreSQL, Volto, and optional Traefik IngressRoute

This Helm chart combines the CloudNativePG PostgreSQL cluster, backend, frontend, and nginx subcharts with the community [Varnish Cache chart](https://github.com/varnish/helm-varnish-cache) to install Plone 6 with RelStorage/PostgreSQL as the database backend, Volto frontend, Varnish as a cache server, and nginx as a reverse proxy server.

Requests flow as follows: ingress → nginx → Varnish → backend pods (for `++api++` requests), and ingress → nginx → frontend (for everything else).

## Prerequisites

The [CloudNativePG](https://cloudnative-pg.io) operator must be installed in your Kubernetes cluster.
See [Install the operator](../README.md#install-the-operator).

## Database

This chart depends on the CloudNativePG `cluster` chart, under the alias `postgresql`.
By default, it creates a single-instance PostgreSQL cluster with a `plone` database.
The operator creates the database volume and generates the credentials in the `<release>-postgresql-app` secret, which the backend uses to connect to the `<release>-postgresql-rw` service.
You don't need to create a PersistentVolumeClaim or a credentials secret.

Set the options of the `cluster` chart under the `postgresql` key, for example for high availability:

```yaml
postgresql:
  cluster:
    instances: 3
    enablePDB: true
```

To use an external database instead, set `postgresql.enabled` to `false` and configure `backend.databasehost` and `backend.dbsecret`.
See [PostgreSQL with CloudNativePG](../README.md#postgresql-with-cloudnativepg) for details.

## Varnish

This repository does not ship its own Varnish chart.
Instead, this chart depends on the `varnish-cache` chart maintained by Varnish Software, published at `oci://registry-1.docker.io/varnish/varnish-cache`.
It is declared in `Chart.yaml` with the alias `varnish`, so its resources are named `<release>-varnish`, which is the name the nginx subchart expects:

```yaml
dependencies:
  - name: "varnish-cache"
    alias: "varnish"
    version: "1.1.1"
    repository: "oci://registry-1.docker.io/varnish"
    import-values:
      - child: server.service.http
        parent: nginx.varnish
```

The `import-values` entry passes the Varnish service port to nginx, which then uses Varnish as its upstream for the backend instead of calling the backend service directly.

### Configuration

The default `values.yaml` configures the community chart as follows:

* two Varnish replicas, run as a StatefulSet, with a PodDisruptionBudget of `minAvailable: 50%`
* a `ClusterIP` service on port `6081`
* a VCL that load balances requests between the backend pods in round-robin, addressing each pod through the headless `<release>-backend-director` service

```yaml
varnish:
  ploneBackendReplicas: 2
  server:
    kind: StatefulSet
    replicas: 2
    pdb:
      enabled: true
      minAvailable: 50%
    service:
      type: ClusterIP
      http:
        port: 6081
    vclConfig: |
      vcl 4.1;

      import directors;

      {{- $name := .Release.Name -}}
      {{- $replicas := .Values.ploneBackendReplicas | int -}}
      {{- range until $replicas }}
      backend backend{{ . }} {
          .host = "{{ $name }}-backend-{{ . }}.{{ $name }}-backend-director";
          .port = "8080";
      }
      {{- end }}

      sub vcl_init {
          new vdir = directors.round_robin();
          {{- range until $replicas }}
          vdir.add_backend(backend{{ . }});
          {{- end }}
      }

      sub vcl_recv {
          set req.backend_hint = vdir.backend();
      }
```

`server.vclConfig` is rendered as a Helm template, so it can use `.Release.Name` and values of the `varnish` section.
If you change `backend.replicaCount`, set `varnish.ploneBackendReplicas` to the same number, so that the VCL declares one backend per pod:

```yaml
backend:
  replicaCount: 3
varnish:
  ploneBackendReplicas: 3
```

To use your own VCL, override `varnish.server.vclConfig`.
See the [varnish-cache chart documentation](https://github.com/varnish/helm-varnish-cache) for all available options, such as resources, autoscaling, and `varnishncsa` logging.

### Using Varnish in your own composite chart

To put Varnish in front of the Plone backend in your own composite chart, add the same dependency and values to it, then run `helm dependency update` to fetch the chart.

