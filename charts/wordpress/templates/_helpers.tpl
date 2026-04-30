{{- define "wparctic.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "wparctic.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "wparctic.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "wparctic.labels" -}}
app.kubernetes.io/name: {{ include "wparctic.name" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "wparctic.wordpressName" -}}
{{- printf "%s-wordpress" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "wparctic.mariadbName" -}}
{{- printf "%s-mariadb" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "wparctic.imageRef" -}}
{{- $repo := .repository -}}
{{- $tag := .tag -}}
{{- $digest := .digest -}}
{{- if $digest -}}
{{- printf "%s@%s" $repo $digest -}}
{{- else -}}
{{- printf "%s:%s" $repo $tag -}}
{{- end -}}
{{- end -}}
