{{/*
Common labels
*/}}
{{- define "plone.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Validate the routing type.
*/}}
{{- define "plone.routing.validate" -}}
{{- $types := list "gateway" "ingress-nginx" "none" -}}
{{- if not (has .Values.routing.type $types) -}}
{{- fail (printf "routing.type must be one of %s, got %q" (join ", " $types) .Values.routing.type) -}}
{{- end -}}
{{- end }}

{{/*
Zope virtual host path that /++api++ is rewritten to, without trailing slash:
/VirtualHostBase/<scheme>/<hostname>:<port>/<siteId>/++api++/VirtualHostRoot
*/}}
{{- define "plone.routing.apiPath" -}}
{{- $r := .Values.routing -}}
{{- $scheme := ternary "https" "http" $r.https -}}
{{- $port := $r.port | default (ternary 443 80 $r.https) -}}
{{- printf "/VirtualHostBase/%s/%s:%v/%s/++api++/VirtualHostRoot" $scheme $r.hostname $port $r.siteId -}}
{{- end }}

{{/*
Services that receive the API requests (Varnish) and all other requests (frontend).
*/}}
{{- define "plone.routing.apiService" -}}
{{- printf "%s-varnish" .Release.Name -}}
{{- end }}

{{- define "plone.routing.apiPort" -}}
{{- .Values.varnish.server.service.http.port -}}
{{- end }}

{{- define "plone.routing.frontendService" -}}
{{- printf "%s-frontend" .Release.Name -}}
{{- end }}

{{- define "plone.routing.frontendPort" -}}
{{- .Values.frontend.service.port -}}
{{- end }}
