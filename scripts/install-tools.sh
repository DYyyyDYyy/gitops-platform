#!/usr/bin/env bash
# Installs pinned CLI tools (versions from .tool-versions) into $BIN_DIR without sudo.
set -euo pipefail

BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$BIN_DIR"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

v() { awk -v t="$1" '$1==t {print $2}' "$ROOT/.tool-versions"; }

have() { # have <bin> <version-substring>
  [[ -x "$BIN_DIR/$1" ]] && "$BIN_DIR/$1" ${3:-version} 2>/dev/null | grep -q -- "$2"
}

get() { curl -fsSL --retry 3 -o "$2" "$1"; }

install_bin() { install -m 0755 "$1" "$BIN_DIR/$2"; echo "installed $2"; }

V=$(v kind)
have kind "$V" || { get "https://github.com/kubernetes-sigs/kind/releases/download/v$V/kind-linux-amd64" "$TMP/kind"; install_bin "$TMP/kind" kind; }

V=$(v kubectl)
have kubectl "v$V" "version --client" || { get "https://dl.k8s.io/release/v$V/bin/linux/amd64/kubectl" "$TMP/kubectl"; install_bin "$TMP/kubectl" kubectl; }

V=$(v helm)
have helm "v$V" || { get "https://get.helm.sh/helm-v$V-linux-amd64.tar.gz" "$TMP/helm.tgz"; tar -xzf "$TMP/helm.tgz" -C "$TMP"; install_bin "$TMP/linux-amd64/helm" helm; }

V=$(v kustomize)
have kustomize "v$V" || { get "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv$V/kustomize_v${V}_linux_amd64.tar.gz" "$TMP/k.tgz"; tar -xzf "$TMP/k.tgz" -C "$TMP"; install_bin "$TMP/kustomize" kustomize; }

V=$(v terraform)
have terraform "v$V" || { get "https://releases.hashicorp.com/terraform/$V/terraform_${V}_linux_amd64.zip" "$TMP/tf.zip"; unzip -oq "$TMP/tf.zip" -d "$TMP"; install_bin "$TMP/terraform" terraform; }

V=$(v sops)
have sops "$V" "--version --disable-version-check" || { get "https://github.com/getsops/sops/releases/download/v$V/sops-v$V.linux.amd64" "$TMP/sops"; install_bin "$TMP/sops" sops; }

V=$(v age)
have age "v$V" "--version" || { get "https://github.com/FiloSottile/age/releases/download/v$V/age-v$V-linux-amd64.tar.gz" "$TMP/age.tgz"; tar -xzf "$TMP/age.tgz" -C "$TMP"; install_bin "$TMP/age/age" age; install_bin "$TMP/age/age-keygen" age-keygen; }

V=$(v kubeconform)
have kubeconform "v$V" "-v" || { get "https://github.com/yannh/kubeconform/releases/download/v$V/kubeconform-linux-amd64.tar.gz" "$TMP/kc.tgz"; tar -xzf "$TMP/kc.tgz" -C "$TMP"; install_bin "$TMP/kubeconform" kubeconform; }

V=$(v kyverno)
have kyverno "$V" || { get "https://github.com/kyverno/kyverno/releases/download/v$V/kyverno-cli_v${V}_linux_x86_64.tar.gz" "$TMP/ky.tgz"; tar -xzf "$TMP/ky.tgz" -C "$TMP"; install_bin "$TMP/kyverno" kyverno; }

V=$(v argocd)
have argocd "v$V" "version --client" || { get "https://github.com/argoproj/argo-cd/releases/download/v$V/argocd-linux-amd64" "$TMP/argocd"; install_bin "$TMP/argocd" argocd; }

V=$(v promtool)
have promtool "$V" "--version" || { get "https://github.com/prometheus/prometheus/releases/download/v$V/prometheus-$V.linux-amd64.tar.gz" "$TMP/p.tgz"; tar -xzf "$TMP/p.tgz" -C "$TMP"; install_bin "$TMP/prometheus-$V.linux-amd64/promtool" promtool; }

echo "tools OK in $BIN_DIR"
