# Operations

## Bootstrap remote state

```bash
cd bootstrap
terraform init
# REVIEW plan — do not run apply in Phase 09A
# terraform apply
# then copy backend.hcl.example, fill bucket, terraform init -migrate-state
```

## Environment apply order (Phase 09B+)

1. nonprod/network
2. nonprod/eks (`vpc_id` and subnet IDs from step 1; restrict API CIDRs)
3. prod/network
4. prod/eks (`ecr_repository_arns` from nonprod outputs; API private)

Always `terraform plan` and operator approval before apply. Never combine legacy destroy and greenfield apply in one script.

## GitHub repository

Local only until authorized:

```bash
gh repo create platform-aws-eks --private --source . --remote origin
```

Do not run that unless the operator asks. Do not push without approval.
