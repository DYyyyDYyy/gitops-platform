#!/usr/bin/env bash
# Offline checks, same as CI: terraform fmt/validate, helm lint, kubeconform, kyverno test, promtool.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT

echo "== terraform"
terraform fmt -check -recursive terraform
terraform -chdir=terraform init -backend=false -input=false >/dev/null
terraform -chdir=terraform validate

echo "== helm lint"
helm lint apps/transport-api clusters/local

echo "== render"
helm template transport-api apps/transport-api -n apps > "$OUT/transport-api.yaml"
helm template root clusters/local -n argocd > "$OUT/root.yaml"
kustomize build platform/monitoring > "$OUT/monitoring.yaml"
cp policies/cluster/*.yaml "$OUT/"

echo "== kubeconform"
kubeconform -strict -summary -ignore-missing-schemas \
  -schema-location default \
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  "$OUT"/*.yaml

echo "== kyverno test"
kyverno test policies/tests
# the app chart itself must pass our own policies
kyverno apply policies/cluster/ --resource "$OUT/transport-api.yaml" \
  --values-file policies/tests/values.yaml --table

echo "== promtool"
# PrometheusRule CR -> plain Prometheus rules file
uv run -q --no-project --with pyyaml==6.0.3 python3 -c '
import sys, yaml, json
print(json.dumps({"groups": yaml.safe_load(open(sys.argv[1]))["spec"]["groups"]}))
' platform/monitoring/alerts.yaml > "$OUT/rules.yaml"
promtool check rules "$OUT/rules.yaml"
cp platform/monitoring/alerts.test.yaml "$OUT/"
promtool test rules "$OUT/alerts.test.yaml"

echo "== image tag consistency"
tag=$(awk '/^  tag:/{print $2; exit}' apps/transport-api/values.yaml)
ref=$(awk '/^APP_REF/{print $3}' Makefile)
[[ "$ref" == "$tag"* ]] || { echo "values tag $tag != Makefile APP_REF $ref" >&2; exit 1; }

echo "lint OK"
