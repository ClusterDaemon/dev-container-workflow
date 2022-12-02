{{/*
Expand the name of the chart.
*/}}
{{- define "dev-container-workflow.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "dev-container-workflow.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "dev-container-workflow.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "dev-container-workflow.labels" -}}
helm.sh/chart: {{ include "dev-container-workflow.chart" . }}
{{ include "dev-container-workflow.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "dev-container-workflow.selectorLabels" -}}
app.kubernetes.io/name: {{ include "dev-container-workflow.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "dev-container-workflow.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "dev-container-workflow.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Determine user and group ID to use in passwd files
*/}}
{{- define "dev-container-workflow.passwd.init" }}
{{- if .Values.initSecurityContext.runAsUser }}
user: {{ .Values.initSecurityContext.runAsUser }}
{{- else if .Values.podSecurityContext.runAsUser }}
user: {{ .Values.podSecurityContext.runAsUser }}
{{- else }}
user: false
{{- end }}
{{- if .Values.initSecurityContext.runAsGroup }}
group: {{ .Values.initSecurityContext.runAsGroup }}
{{- else if .Values.podSecurityContext.runAsGroup }}
group: {{ .Values.podSecurityContext.runAsGroup }}
{{- else }}
group: false
{{- end }}
{{- end }}

{{- define "dev-container-workflow.passwd" }}
{{- if .Values.securityContext.runAsUser }}
user: {{ .Values.securityContext.runAsUser }}
{{- else if .Values.podSecurityContext.runAsUser }}
user: {{ .Values.podSecurityContext.runAsUser }}
{{- else }}
user: false
{{- end }}
{{- if .Values.securityContext.runAsGroup }}
group: {{ .Values.securityContext.runAsGroup }}
{{- else if .Values.podSecurityContext.runAsGroup }}
group: {{ .Values.podSecurityContext.runAsGroup }}
{{- else }}
group: false
{{- end }}
{{- end }}

{{- define "dev-container-workflow.float64ToBool" }}
{{- if and (kindIs "float64" .) (gt . (float64 0)) }}
result: true
{{- else if kindIs "bool" . }}
{{ . }}
{{- else }}
result: false
{{- end }}
{{- end }}
