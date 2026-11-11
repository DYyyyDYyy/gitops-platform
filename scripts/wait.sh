#!/usr/bin/env bash
# Waits until every Argo CD Application is Synced + Healthy and the API answers through ingress.
set -euo pipefail
TIMEOUT="${TIMEOUT:-900}"
deadline=$(( $(date +%s) + TIMEOUT ))

until kubectl -n argocd get application root >/dev/null 2>&1; do sleep 5; done

while :; do
  bad=$(kubectl -n argocd get applications -o json \
    | jq -r '.items[] | select(.status.sync.status != "Synced" or .status.health.status != "Healthy")
             | "\(.metadata.name)=\(.status.sync.status)/\(.status.health.status)"')
  total=$(kubectl -n argocd get applications --no-headers 2>/dev/null | wc -l)
  if [[ -z "$bad" && "$total" -ge 10 ]]; then break; fi
  if (( $(date +%s) > deadline )); then
    echo "timeout; not ready: $bad" >&2
    kubectl -n argocd get applications >&2
    exit 1
  fi
  echo "waiting ($total apps): ${bad//$'\n'/ }"
  sleep 15
done
kubectl -n argocd get applications

kubectl -n apps rollout status deploy/transport-api --timeout=300s
for _ in $(seq 30); do
  if curl -fsS -H 'Host: api.localhost' http://127.0.0.1/health; then echo; exit 0; fi
  sleep 5
done
echo "API /health did not answer" >&2
exit 1
