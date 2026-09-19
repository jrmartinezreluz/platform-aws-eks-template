# Pod Security Standards (10B)

| Namespace | enforce | audit/warn | version |
|-----------|---------|------------|---------|
| default | baseline | restricted | v1.35 |
| security-validation | restricted | restricted | v1.35 |
| platform (kube-system, monitoring, argocd, …) | unlabeled / exempt | — | — |

Do not set cluster-wide `enforce=restricted`. Git: `namespace-default.yaml`.
