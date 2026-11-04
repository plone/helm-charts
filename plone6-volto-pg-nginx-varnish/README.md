# Install Plone 6 with RelStorage/PostgreSQL, Volto, and optional Traefik IngressRoute

This Helm chart combines the PostgreSQL, backend, frontend, and nginx subcharts with the community [Varnish Cache chart](https://github.com/varnish/helm-varnish-cache) to install Plone 6 with RelStorage/PostgreSQL as the database backend, Volto frontend, Varnish as a cache server, and nginx as a reverse proxy server.

Requests flow as follows: ingress → nginx → Varnish → backend pods (for `++api++` requests), and ingress → nginx → frontend (for everything else).

## Prerequisites

You need a persistent volume claim to hold the PostgreSQL database and a secret to provide the database credentials.

### Database persistent volume claim

The PostgreSQL subchart expects a Persistent Volume Claim with a default name of `db-pvc` for the database (PGDATA) directory.
Override the default in `values.yaml` with:

```yaml
postgresql:
  persistentVolumeClaim:
    claimName: <your-pvc>
```

### Database credentials

Database credentials (database name, user name, and password) are expected in a secret.
The secret name defaults to `plonedb`.

Using the `kubectl` command, you can create a secret.

```shell
kubectl create secret generic plonedb \
    --from-literal=database-name='plone' \
    --from-literal=database-user='plone' \
    --from-literal=database-password='plone'
```

You can override the default secret name in `values.yaml`:

```yaml
postgresql:
  dbsecret:
    name: <your-secret>
```

See also the Kubernetes documentation [Create a Secret](https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/#create-a-secret).

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

