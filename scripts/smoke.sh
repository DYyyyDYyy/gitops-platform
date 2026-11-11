#!/usr/bin/env bash
# Live checks against the running cluster ("done" criteria from the README).
set -euo pipefail
cd "$(dirname "$0")/.."
fail() { echo "FAIL: $*" >&2; exit 1; }

echo "== Argo CD apps Synced/Healthy"
bad=$(kubectl -n argocd get applications -o json | jq -r '.items[]
  | select(.status.sync.status != "Synced" or .status.health.status != "Healthy") | .metadata.name')
[[ -z "$bad" ]] || fail "not healthy: $bad"

echo "== API /health via ingress"
curl -fsS -H 'Host: api.localhost' http://127.0.0.1/health | grep -q '"ok"' || fail "/health"

echo "== Kyverno rejects a bad manifest in apps"
if out=$(kubectl apply --dry-run=server -f - 2>&1 <<'EOF'
apiVersion: v1
kind: Pod
metadata: { name: bad, namespace: apps }
spec:
  # PSS-restricted compliant, so the only violation is Kyverno's no-latest rule
  securityContext: { runAsNonRoot: true, runAsUser: 10001, seccompProfile: { type: RuntimeDefault } }
  containers:
    - name: c
      image: "nginx:latest"
      resources: { requests: { cpu: 10m, memory: 16Mi }, limits: { memory: 32Mi } }
      securityContext: { allowPrivilegeEscalation: false, capabilities: { drop: [ALL] } }
EOF
); then fail "bad pod was admitted"; fi
grep -q disallow-latest-tag <<<"$out" || fail "rejected, but not by Kyverno: $out"
echo "rejected: ok"

echo "== Grafana has the dashboard"
pw=$(kubectl -n monitoring get secret grafana-admin -o jsonpath='{.data.admin-password}' | base64 -d)
curl -fsS -u "admin:$pw" -H 'Host: grafana.localhost' http://127.0.0.1/api/dashboards/uid/transport-api \
  | jq -e '.dashboard.title == "Transport API"' >/dev/null || fail "dashboard"

echo "== Prometheus scrapes the API and has our rules"
kubectl -n monitoring get prometheusrule platform-alerts >/dev/null || fail "rules"
q='up{namespace="apps",service="transport-api"}'
kubectl get --raw "/api/v1/namespaces/monitoring/services/kube-prometheus-stack-prometheus:9090/proxy/api/v1/query?query=$(jq -rn --arg q "$q" '$q|@uri')" \
  | jq -e '[.data.result[] | select(.value[1]=="1")] | length >= 1' >/dev/null || fail "API not scraped"

echo "smoke OK"
