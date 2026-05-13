{{- define "apache-datasvc.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "apache-datasvc.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-apache" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "apache-datasvc.labels" -}}
app.kubernetes.io/name: {{ include "apache-datasvc.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "apache-datasvc.ingressHosts" -}}
{{- $hosts := list .Values.ingress.hostname -}}
{{- if .Values.ingress.tlsWwwPrefix -}}
{{- $hosts = append $hosts (printf "www.%s" .Values.ingress.hostname) -}}
{{- end -}}
{{- toYaml $hosts -}}
{{- end -}}
