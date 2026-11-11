#!/usr/bin/env bash
# Puts secrets into the cluster. With an age key: decrypt secrets/*.enc.yaml (SOPS).
# Without one (CI, fresh clone): generate throw-away random values with the same names/keys.
set -euo pipefail
cd "$(dirname "$0")/.."

KEY="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

if [[ -f "$KEY" ]] || [[ -n "${SOPS_AGE_KEY:-}" ]]; then
  for f in secrets/*.enc.yaml; do
    sops decrypt "$f" | kubectl apply -f -
  done
  exit 0
fi

echo "no age key found -> ephemeral secrets" >&2
rnd() { head -c 24 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 24; }
pw="$(rnd)"
kubectl -n apps create secret generic transport-db \
  --from-literal=POSTGRES_USER=transport \
  --from-literal=POSTGRES_DB=transport_firm \
  --from-literal=POSTGRES_PASSWORD="$pw" \
  --from-literal=DATABASE_URL="postgresql+psycopg2://transport:${pw}@transport-db:5432/transport_firm" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n monitoring create secret generic grafana-admin \
  --from-literal=admin-user=admin --from-literal=admin-password="$(rnd)" \
  --dry-run=client -o yaml | kubectl apply -f -
