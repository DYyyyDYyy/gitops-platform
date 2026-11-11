# 4. kind instead of a cloud cluster

**Status:** accepted

**Context.** The project has to run for free with no cloud account, and has to run the same way on a laptop and in GitHub Actions.

**Decision.** Terraform (`tehcyx/kind`) creates a kind cluster with 1 control-plane and 2 workers. Ports 80/443 map to 127.0.0.1, and hostnames use `*.localhost`. State is local and git-ignored. The app image is built locally and loaded with `kind load`, with no registry involved.

**Consequences.** There is no real load balancer, IAM or managed database (see "Not here" in the README). The Terraform workflow (plan in CI, apply, providers wired from resource outputs) is the same one used for EKS.
