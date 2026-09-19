# IAM

- Cluster role + node instance role (SSM + ECR pull + CNI)
- EBS/EFS CSI via **EKS Pod Identity** (trust `pods.eks.amazonaws.com`)
- GitHub Actions OIDC: `gha-ecr-push-nonprod` / `gha-ecr-push-prod`
- `sub` claims: `repo:<org>/<repo>:environment:<env>` (dev, staging, uat, production as applicable)
- OIDC provider is **not** created by default. This sandbox account already has `token.actions.githubusercontent.com`. Set `create_github_oidc_provider=true` only in an account that lacks the provider.

Prod ECR push role still exists so production GitHub Environment workflows can promote the same digest; it does not create a second registry.

Do not put static AWS keys in GitHub. Do not use `repo:...:*` wildcard subjects.
