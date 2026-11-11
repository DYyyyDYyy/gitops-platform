{{- define "api.labels" -}}
app.kubernetes.io/name: transport-api
app.kubernetes.io/part-of: transport-firm
{{- end }}

{{- define "api.selector" -}}
app.kubernetes.io/name: transport-api
{{- end }}

{{- define "db.selector" -}}
app.kubernetes.io/name: transport-db
{{- end }}

{{/* restricted Pod Security profile */}}
{{- define "restricted.container" -}}
allowPrivilegeEscalation: false
readOnlyRootFilesystem: true
capabilities:
  drop: [ALL]
{{- end }}
