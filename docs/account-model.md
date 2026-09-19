# Account model

**PENDING OPERATOR.** Live caller identity was unavailable during design (`NoCredentials`).

Until dedicated accounts are mapped:

- one AWS account
- two clusters (`eks-nonprod`, `eks-prod`)
- two VPCs (`vpc-nonprod`, `vpc-prod`)
- one GitHub OIDC provider (created with nonprod IAM)
- one canonical ECR set (nonprod registry module)

Do not publish account IDs in this repository.

If the operator later splits accounts, keep build-once/promote-many via ECR replication of the same digest. Do not rebuild images per account.
