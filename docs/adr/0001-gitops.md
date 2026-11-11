# 1. GitOps with Argo CD

**Status:** accepted

**Context.** The cluster must be reproducible from zero, and every change must be reviewable.

**Decision.** Terraform builds only the cluster and installs Argo CD. Everything after that (platform charts, policies, dashboards, the app) is declared in this repo, and Argo CD syncs it with automated prune and self-heal.

**Consequences.** A change means a commit, and `git log` doubles as the audit trail. Manual `kubectl edit` gets reverted. Secrets need a separate path (ADR 3). CI tests the exact commit by passing its SHA as `git_revision`.
