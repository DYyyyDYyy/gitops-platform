# 3. SOPS + age instead of Vault

**Status:** accepted

**Context.** The platform needs a DB password and a Grafana admin password. The Docker budget is 6 GB, and Vault would bring HA storage, unsealing and its own operations.

**Decision.** Secrets live in `secrets/*.enc.yaml`, encrypted with SOPS for one age recipient (`.sops.yaml`, where only `data`/`stringData` are encrypted). The private key stays at `~/.config/sops/age/keys.txt` and never enters git. `make up` decrypts and applies the secrets before Argo CD syncs. Without a key (in CI or a fresh clone) it generates random throw-away secrets.

**Consequences.** Secrets are versioned and reviewable as diffs of key names. Rotation means re-encrypting and committing. Argo CD does not manage Secret objects; KSOPS or External Secrets would be the next step.
