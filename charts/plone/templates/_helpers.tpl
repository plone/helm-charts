{{/*
Expand the name of the chart.
*/}}
{{- define "plone.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Prefix of the resource names: the release name, unless overridden.
The components are named <fullname>-backend, <fullname>-frontend, and so on.
Truncated at 44 characters, so that the component names fit the 52 characters
of a StatefulSet name, such as the one of the ZEO server, whose pods have a
label with the name and a hash.
*/}}
{{- define "plone.fullname" -}}
{{- default .Release.Name .Values.fullnameOverride | trunc 44 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "plone.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ include "plone.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels of a component. Call with (dict "context" . "component" "backend").
*/}}
{{- define "plone.selectorLabels" -}}
app.kubernetes.io/name: {{ include "plone.name" .context }}
app.kubernetes.io/instance: {{ .context.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
Name of the resources of a dependency, following the fullname convention of
the cnpg/cluster and varnish-cache charts.
Call with (dict "context" . "name" "postgresql" "values" .Values.postgresql).
*/}}
{{- define "plone.dependencyFullname" -}}
{{- $release := .context.Release.Name -}}
{{- if .values.fullnameOverride -}}
{{- .values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .name .values.nameOverride -}}
{{- if contains $name $release -}}
{{- $release | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" $release $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Validate the combination of values.
*/}}
{{- define "plone.validate" -}}
{{- $storageTypes := list "relstorage" "zeo" -}}
{{- if not (has .Values.storage.type $storageTypes) -}}
{{- fail (printf "storage.type must be one of %s, got %q" (join ", " $storageTypes) .Values.storage.type) -}}
{{- end -}}
{{- $routingTypes := list "gateway" "ingress-nginx" "none" -}}
{{- if not (has .Values.routing.type $routingTypes) -}}
{{- fail (printf "routing.type must be one of %s, got %q" (join ", " $routingTypes) .Values.routing.type) -}}
{{- end -}}
{{- if .Values.varnish.enabled -}}
{{- $s := .Values.varnish.server -}}
{{- if or $s.vclConfig (hasKey ($s.vclConfigs | default dict) (base $s.vclConfigPath)) -}}
{{- fail "Set the VCL of Varnish with varnish.vcl, which is rendered with the values of this chart, instead of varnish.server.vclConfig or varnish.server.vclConfigs" -}}
{{- end -}}
{{- end -}}
{{- if and (eq .Values.routing.type "gateway") (not .Values.routing.gateway.name) (empty .Values.routing.gateway.parentRefs) -}}
{{- fail "routing.gateway.name is required with routing.type gateway: set it to the Gateway that serves the site (see https://github.com/plone/helm-charts#gateway-api), or set routing.type to none" -}}
{{- end -}}
{{- if eq .Values.storage.type "relstorage" -}}
{{- if and (not .Values.postgresql.enabled) (or (not .Values.storage.relstorage.host) (not .Values.storage.relstorage.secret.name)) -}}
{{- fail "storage.relstorage.host and storage.relstorage.secret.name are required with postgresql.enabled false" -}}
{{- end -}}
{{- else if .Values.postgresql.enabled -}}
{{- fail "storage.type zeo doesn't use PostgreSQL: set postgresql.enabled to false" -}}
{{- end -}}
{{- end }}

{{/*
Secret and key of the password of the admin user of the Zope root:
site.admin.existingSecret, or the Secret that the chart generates.
*/}}
{{- define "plone.admin.secretName" -}}
{{- .Values.site.admin.existingSecret | default (printf "%s-admin" (include "plone.fullname" .)) -}}
{{- end }}

{{- define "plone.admin.secretKey" -}}
{{- ternary .Values.site.admin.passwordKey "password" (not (empty .Values.site.admin.existingSecret)) -}}
{{- end }}

{{/*
Init container that writes the inituser file of Zope, with the admin password
of the Secret. At each start, while the Zope root has no other user, Zope
replaces the admin user with the one of /app/inituser. Without this, every new
pod would restore the password "admin" of the inituser file of the image.
Zope splits the line on colons and strips spaces, so the password can't have a
colon, or start or end with a space.
*/}}
{{- define "plone.admin.initContainer" -}}
{{- $b := .Values.backend -}}
- name: admin-password
  image: "{{ $b.image.repository }}:{{ $b.image.tag | default .Chart.AppVersion }}"
  imagePullPolicy: {{ $b.image.pullPolicy }}
  {{- with $b.securityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  command:
    - /bin/sh
    - -c
    - |
      case "$ADMIN_PASSWORD" in
        "" | *:* | " "* | *" ")
          echo "The admin password in the Secret {{ include "plone.admin.secretName" . }} must not be empty, have a colon (:), or start or end with a space." >&2
          exit 1 ;;
      esac
      printf 'admin:%s\n' "$ADMIN_PASSWORD" > /admin/inituser
  env:
    - name: ADMIN_PASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ include "plone.admin.secretName" . }}
          key: {{ include "plone.admin.secretKey" . }}
  volumeMounts:
    - name: admin
      mountPath: /admin
{{- end }}

{{/*
Volume and mount of the inituser file written by plone.admin.initContainer. The
volume is in memory, so that the password isn't written to the node's disk.
*/}}
{{- define "plone.admin.volume" -}}
- name: admin
  emptyDir:
    medium: Memory
    sizeLimit: 1Mi
{{- end }}

{{- define "plone.admin.volumeMount" -}}
- name: admin
  mountPath: /app/inituser
  subPath: inituser
  readOnly: true
{{- end }}

{{/*
Whether this chart deploys the ZEO server.
*/}}
{{- define "plone.zeo.enabled" -}}
{{- if and (eq .Values.storage.type "zeo") (not .Values.storage.zeo.address) -}}
true
{{- end -}}
{{- end }}

{{/*
Environment variables that configure the storage of the plone-backend image.
*/}}
{{- define "plone.storageEnv" -}}
{{- /* The password can't have ' or \, see docs/how-to/use-external-postgresql.md. */ -}}
{{- if eq .Values.storage.type "relstorage" -}}
{{- $r := .Values.storage.relstorage -}}
{{- $cluster := include "plone.dependencyFullname" (dict "context" . "name" "postgresql" "values" .Values.postgresql) -}}
{{- $host := $r.host | default (printf "%s-rw" $cluster) -}}
{{- $secret := $r.secret.name | default (printf "%s-app" $cluster) -}}
{{- $defaultKeys := dict "database" "database-name" "user" "database-user" "password" "database-password" -}}
{{- if .Values.postgresql.enabled -}}
{{- $defaultKeys = dict "database" "dbname" "user" "username" "password" "password" -}}
{{- end -}}
{{- $keys := merge (deepCopy ($r.secret.keys | default dict)) $defaultKeys -}}
- name: DBHOST
  value: {{ $host | quote }}
- name: DBPORT
  value: {{ $r.port | quote }}
- name: DBNAME
  valueFrom:
    secretKeyRef:
      name: {{ $secret }}
      key: {{ $keys.database }}
- name: DBUSER
  valueFrom:
    secretKeyRef:
      name: {{ $secret }}
      key: {{ $keys.user }}
- name: DBPASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ $secret }}
      key: {{ $keys.password }}
- name: RELSTORAGE_DSN
  value: "host='$(DBHOST)' port='$(DBPORT)' dbname='$(DBNAME)' user='$(DBUSER)' password='$(DBPASSWORD)'"
- name: RELSTORAGE_KEEP_HISTORY
  value: {{ $r.keepHistory | quote }}
- name: RELSTORAGE_BLOB_CACHE_SIZE
  value: {{ $r.blobCacheSize | quote }}
{{- else -}}
- name: ZEO_ADDRESS
  value: {{ .Values.storage.zeo.address | default (printf "%s-zeo:8100" (include "plone.fullname" .)) | quote }}
- name: ZEO_CLIENT_CACHE_SIZE
  value: {{ .Values.storage.zeo.clientCacheSize | quote }}
{{- end -}}
{{- end }}

{{/*
Default VCL of Varnish. It sends the requests to the backend and frontend
Services, which balance the connections of Varnish between their pods.
*/}}
{{- define "plone.varnish.defaultVcl" -}}
vcl 4.1;

# The Plone backend: the API requests with Volto, all requests with the
# Classic UI.
backend plone {
    .host = "{{ include "plone.fullname" . }}-backend";
    .port = "{{ .Values.backend.service.port }}";
}
{{- if .Values.frontend.enabled }}

# The Volto frontend: the pages and static assets of the site.
backend volto {
    .host = "{{ include "plone.fullname" . }}-frontend";
    .port = "{{ .Values.frontend.service.port }}";
}
{{- end }}

sub vcl_recv {
    {{- if .Values.frontend.enabled }}
    # The routing rewrites the API requests to Zope virtual host paths.
    if (req.url ~ "^/VirtualHostBase/") {
        set req.backend_hint = plone;
    } else {
        set req.backend_hint = volto;
        # The static assets of Volto don't depend on cookies, which
        # would prevent caching them.
        if (req.url ~ "^/static/") {
            unset req.http.Cookie;
        }
    }
    {{- else }}
    set req.backend_hint = plone;
    {{- end }}
}
{{- end }}

{{/*
Service and port of the backend as seen by the routing: Varnish if enabled,
the backend otherwise.
*/}}
{{- define "plone.routing.backendService" -}}
{{- if .Values.varnish.enabled -}}
{{- include "plone.dependencyFullname" (dict "context" . "name" "varnish" "values" .Values.varnish) -}}
{{- else -}}
{{- printf "%s-backend" (include "plone.fullname" .) -}}
{{- end -}}
{{- end }}

{{- define "plone.routing.backendPort" -}}
{{- if .Values.varnish.enabled -}}
{{- .Values.varnish.server.service.http.port -}}
{{- else -}}
{{- .Values.backend.service.port -}}
{{- end -}}
{{- end }}

{{/*
parentRefs of the HTTPRoute: routing.gateway.parentRefs if set, or the
Gateway of routing.gateway.name, namespace, and sectionName.
*/}}
{{- define "plone.routing.parentRefs" -}}
{{- $g := .Values.routing.gateway -}}
{{- if $g.parentRefs -}}
{{- toYaml $g.parentRefs -}}
{{- else -}}
- name: {{ $g.name | quote }}
{{- with $g.namespace }}
  namespace: {{ . | quote }}
{{- end }}
{{- with $g.sectionName }}
  sectionName: {{ . | quote }}
{{- end }}
{{- end -}}
{{- end }}

{{/*
Service and port of the frontend as seen by the routing: Varnish if enabled,
which caches the frontend too, the frontend otherwise.
*/}}
{{- define "plone.routing.frontendService" -}}
{{- if .Values.varnish.enabled -}}
{{- include "plone.dependencyFullname" (dict "context" . "name" "varnish" "values" .Values.varnish) -}}
{{- else -}}
{{- printf "%s-frontend" (include "plone.fullname" .) -}}
{{- end -}}
{{- end }}

{{- define "plone.routing.frontendPort" -}}
{{- if .Values.varnish.enabled -}}
{{- .Values.varnish.server.service.http.port -}}
{{- else -}}
{{- .Values.frontend.service.port -}}
{{- end -}}
{{- end }}

{{/*
Zope virtual host path that the backend requests are rewritten to, without
trailing slash:
- with Volto: /VirtualHostBase/<scheme>/<hostname>:<port>/<site>/++api++/VirtualHostRoot
- with the Classic UI: /VirtualHostBase/<scheme>/<hostname>:<port>/<site>/VirtualHostRoot
*/}}
{{- define "plone.routing.backendPath" -}}
{{- $r := .Values.routing -}}
{{- $scheme := ternary "https" "http" $r.https -}}
{{- $port := $r.port | default (ternary 443 80 $r.https) -}}
{{- $api := ternary "/++api++" "" .Values.frontend.enabled -}}
{{- printf "/VirtualHostBase/%s/%s:%v/%s%s/VirtualHostRoot" $scheme $r.hostname $port .Values.site.id $api -}}
{{- end }}

{{/*
Public URL of the site.
*/}}
{{- define "plone.url" -}}
{{- $r := .Values.routing -}}
{{- $scheme := ternary "https" "http" $r.https -}}
{{- $port := $r.port | default (ternary 443 80 $r.https) | toString -}}
{{- if or (and $r.https (eq $port "443")) (and (not $r.https) (eq $port "80")) -}}
{{- printf "%s://%s" $scheme $r.hostname -}}
{{- else -}}
{{- printf "%s://%s:%s" $scheme $r.hostname $port -}}
{{- end -}}
{{- end }}
