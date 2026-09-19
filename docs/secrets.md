# Secrets

Terraform creates **empty** Secrets Manager containers only.

```text
apps/<solution>/<environment>/<secret>
platform/argocd/github-app
```

Environments: `dev`, `staging`, `uat`, `production`.

Operators load values with an approved secret manager workflow. Never commit values, never put them in `.tfvars`, never `secret_string` in Terraform.

Kubernetes consumption: External Secrets Operator → ClusterSecretStore `aws-secrets-manager`.
