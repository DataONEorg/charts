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

{{- define "wparctic.wordpressDeployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "wparctic.wordpressName" . }}-{{ .role }}
  labels:
{{ include "wparctic.labels" . | nindent 4 }}
    app.kubernetes.io/component: wordpress
spec:
  replicas: {{ .replicas }}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  selector:
    matchLabels:
      app.kubernetes.io/instance: {{ .Release.Name }}
      app.kubernetes.io/component: wordpress
      app.kubernetes.io/role: {{ .role }}
  template:
    metadata:
      labels:
{{ include "wparctic.labels" . | nindent 8 }}
        app.kubernetes.io/component: wordpress
        app.kubernetes.io/role: {{ .role }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
{{ toYaml . | nindent 8 }}
      {{- end }}
      securityContext:
{{ toYaml .Values.podSecurityContext | nindent 8 }}
      containers:
        - name: wordpress
          image: {{ include "wparctic.imageRef" .Values.wordpress.image }}
          imagePullPolicy: {{ .Values.wordpress.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 80
          env:
            - name: WORDPRESS_DB_HOST
              value: {{ include "wparctic.mariadbName" . | quote }}
            - name: WORDPRESS_DB_USER
              value: {{ .Values.mariadb.auth.username | quote }}
            - name: WORDPRESS_DB_NAME
              value: {{ .Values.mariadb.auth.database | quote }}
            - name: WORDPRESS_DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ .Values.mariadb.existingSecret }}
                  key: {{ .Values.mariadb.auth.passwordSecretKey }}
            - name: WORDPRESS_CONFIG_EXTRA
              value: |
                define('WP_HOME', 'https://{{ .Values.ingress.host }}');
                define('WP_SITEURL', 'https://{{ .Values.ingress.host }}');
                define( 'FORCE_SSL_ADMIN', true );
                if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && strpos($_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false) $_SERVER['HTTPS'] = 'on';
                define('WP_AUTO_UPDATE_CORE', false);
                {{- if .disallowFileMods }}
                define('DISALLOW_FILE_MODS', true);
                {{- end }}
          readinessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 15
            periodSeconds: 10
            timeoutSeconds: 5
          livenessProbe:
            httpGet:
              path: /wp-login.php
              port: http
            initialDelaySeconds: 60
            periodSeconds: 20
            timeoutSeconds: 5
          resources:
            {{ toYaml .Values.wordpress.resources | nindent 12 }}
          volumeMounts:
            - name: wordpress-data
              mountPath: /var/www/html
              {{- if .readOnlyVolume }}
              readOnly: true
              {{- end }}
            {{- if .Values.robotsTxt.enabled }}
            - name: robots-txt
              mountPath: /var/www/html/robots.txt
              subPath: {{ .Values.robotsTxt.key }}
            {{- end }}
      volumes:
        - name: wordpress-data
          persistentVolumeClaim:
            claimName: {{ .Values.wordpress.persistence.existingClaim }}
        {{- if .Values.robotsTxt.enabled }}
        - name: robots-txt
          configMap:
            name: {{ .Values.robotsTxt.existingConfigMap }}
        {{- end }}
{{- end -}}
