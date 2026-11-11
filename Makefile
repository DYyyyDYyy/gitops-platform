SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c
export PATH := $(HOME)/.local/bin:$(PATH)

CLUSTER     ?= gitops
TF_DIR      := terraform
APP_REPO    ?= https://github.com/DYyyyDYyy/rest-api-transport-firm.git
APP_REF     ?= fd3fea549ecb92ee7ff98fd5638e0ccfcbc4aabc
# tag lives in git (apps/transport-api/values.yaml) so Argo CD and the local build agree
IMAGE_TAG   := $(shell awk '/^  tag:/{print $$2; exit}' apps/transport-api/values.yaml)
IMAGE       := transport-api:$(IMAGE_TAG)
GIT_REV     ?= main
KUBECONFIG  := $(CURDIR)/.kube/config
export KUBECONFIG

.PHONY: tools up down status test lint image secrets wait

tools: ## install pinned CLIs into ~/.local/bin
	./scripts/install-tools.sh
	docker info --format 'docker {{.ServerVersion}}, {{.NCPU}} CPU, {{.MemTotal}} bytes'

image: ## build demo API image
	docker build -t $(IMAGE) --build-arg APP_REPO=$(APP_REPO) --build-arg APP_REF=$(APP_REF) image

up: image ## cluster from zero to working platform
	terraform -chdir=$(TF_DIR) init -input=false
	# 1) cluster + namespaces, 2) image and secrets in place, 3) Argo CD takes over from git
	terraform -chdir=$(TF_DIR) apply -input=false -auto-approve -var git_revision=$(GIT_REV) \
	  -target=kubernetes_namespace_v1.apps -target=kubernetes_namespace_v1.monitoring
	kind load docker-image $(IMAGE) --name $(CLUSTER)
	./scripts/secrets.sh
	terraform -chdir=$(TF_DIR) apply -input=false -auto-approve -var git_revision=$(GIT_REV)
	./scripts/wait.sh

secrets: ## decrypt SOPS secrets into the cluster (ephemeral random ones if no age key, e.g. in CI)
	./scripts/secrets.sh

wait: ## wait until all Argo CD apps are Synced/Healthy and API answers
	./scripts/wait.sh

down: ## destroy the cluster completely (everything in it is disposable; state is local)
	kind delete cluster --name $(CLUSTER)
	rm -f $(TF_DIR)/terraform.tfstate $(TF_DIR)/terraform.tfstate.backup .kube/config

status: ## nodes, Argo CD apps, URLs and logins
	kubectl get nodes
	kubectl -n argocd get applications
	@echo "Argo CD: http://argocd.localhost  admin / $$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
	@echo "Grafana: http://grafana.localhost admin / $$(kubectl -n monitoring get secret grafana-admin -o jsonpath='{.data.admin-password}' | base64 -d)"
	@echo "API:     http://api.localhost/docs"

lint: ## offline checks (also run in CI)
	./scripts/lint.sh

test: lint ## lint + live checks against the running cluster
	./scripts/smoke.sh
