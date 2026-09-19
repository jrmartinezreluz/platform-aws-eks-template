# Admission policies (10D)

| Path | Role |
|------|------|
| `audit/tier0-audit.yaml` | Cluster-wide Audit |
| `enforce/security-validation.yaml` | Enforce on `security-validation` |
| `enforce/cosign-public-key.yaml` | Public key ConfigMap (not the private key) |
| `exceptions/security-validation-np-proof.yaml` | NP proof exception |
| `cosign.pub` | Cosign public key |
| `tests/` | `kyverno test` fixtures |

Live Cosign matrix: `scripts/admission-validate.sh`. Offline: `scripts/admission-policy-test.sh`.
