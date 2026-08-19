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

{{/*
Create a checksum that reflects changes in the config files.
Do it here, instead of in deployment.yaml, because helm's ordering of operations means that the
checksum is performed before the values overrides are inserted into the config files, so the
checksum doesn't change when those values do.
*/}}
{{- define "apache.config.checksum" -}}
{{- $out := "" }}
{{- range $path, $file := .Files.Glob "templates/*" }}
  {{- $content := toString $file }}
  {{- $rendered := tpl $content $ }}
  {{- $out = printf "%s\n%s" $out $rendered }}
{{- end }}
{{- $out | trim | sha256sum -}}
{{- end -}}
