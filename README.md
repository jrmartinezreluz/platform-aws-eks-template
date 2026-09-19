# platform-aws-eks-template

Sanitized **production-oriented reference architecture** for a private Amazon EKS platform using Terraform, GitOps add-on skeletons, IRSA, admission policy examples, observability, and backup patterns.

This is a **curated public template**. It is **not** a live operational environment and is **not** a mirror of any private repository.

## What this template demonstrates

- Two-VPC layout (`nonprod` / `prod`) plus an optional private access VPC
- Private EKS API endpoints (operator access via a separate access network, not a public API CIDR)
- Managed node groups, EKS add-ons, IRSA
- GitHub Actions OIDC trust restricted by repository and environment
- GitOps-owned add-ons (Argo CD hub, Rollouts, External Secrets, cert-manager, Traefik, observability, Velero)
- AWS Backup + Velero architecture patterns
- NetworkPolicy / Pod Security / Kyverno **examples** (fail-closed posture documented)

## Architecture

```text
bootstrap (S3 state)
  → vpc-nonprod (10.10.0.0/16) → eks-nonprod
  → vpc-prod    (10.20.0.0/16) → eks-prod
  → vpc-access  (10.30.0.0/16) → optional WireGuard access
GitOps hub: Argo CD on eks-nonprod
Destinations: cluster-nonprod, cluster-prod
Artifacts: build once, push digest, promote the same digest
```

See `docs/architecture.md`.

## Prerequisites

- Terraform `>= 1.10`
- AWS credentials with rights to create VPC/EKS/IAM in **your** account
- A state backend you control (`backend.example.hcl`)
- kubectl + a GitOps repository for add-on/app delivery

## Cost considerations

This architecture can incur **meaningful AWS cost**. Typical categories:

- EKS control plane (per cluster)
- EC2 managed node groups
- NAT Gateway
- load balancers
- CloudWatch
- EBS/EFS
- backup storage
- data transfer

Destroy unused stacks. A sandbox with two clusters plus NAT is not free.

## Security model

- Private EKS endpoints by default
- IRSA for add-on service accounts (EKS Pod Identity is not assumed)
- GitHub OIDC `sub` restricted to `repo:<owner>@*/<repo>@*:environment:<env>`
- Inspect real GitHub token claims: GitHub may emit unique repository IDs
- Secrets Manager **containers** in Terraform; secret **values** stay out of Git
- Cosign key material is **yours** — the ConfigMap is a placeholder

## How to deploy (example)

1. Copy `backend.example.hcl` → `backend.hcl` with **your** bucket.
2. Copy `terraform.tfvars.example` → `terraform.tfvars` with **your** VPC IDs and principals.
3. `terraform init -backend-config=backend.hcl` then plan/apply **one stack at a time**:
   `bootstrap` → `environments/nonprod/network` → `environments/nonprod/eks` → prod equivalents.
4. Supply GitOps add-on values from `gitops/addons/` in **your** GitOps repo. Do not point a live cluster at this public template.

## How to destroy

Destroy in reverse order (workloads/GitOps first, then EKS, then network, then bootstrap). Confirm the AWS account and region before any destroy.

## Known limitations

- Offline `terraform validate` does not prove an AWS apply will succeed.
- Add-on YAML is example-grade; versions must be confirmed against EKS add-on APIs.
- Backup/DR examples are regional patterns, not a multi-region failover product.
- This template is **not** certified production-ready for every context.

## Intentionally excluded

- Live account IDs, VPC/subnet/SG IDs, EIPs, kubeconfigs, WireGuard keys
- Real Terraform state and backend names
- Operational Cosign private/public keys
- Private runbooks with tenant identifiers

## License

Apache-2.0. See `LICENSE` and `SECURITY.md`.
