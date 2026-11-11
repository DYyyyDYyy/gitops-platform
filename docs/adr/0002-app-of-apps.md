# 2. App-of-apps rendered by a small Helm chart

**Status:** accepted

**Context.** Nine Applications need the same repoURL, revision, retry and sync options. They also need an install order: CRDs first, the app last.

**Decision.** Terraform creates a single root Application. It points at `clusters/local`, a Helm chart that renders one Application per entry in `values.yaml`. Each entry uses either an upstream chart (with values from `platform/<name>/values.yaml` via multi-source `$values`) or a path in this repo. Sync waves set the order, and a health check on Application resources makes the waves actually wait.

**Consequences.** Adding a component means one values entry plus one values file. ApplicationSet was rejected as overkill for a single cluster.
