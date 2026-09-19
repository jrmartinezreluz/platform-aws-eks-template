# Architecture

Greenfield EKS platform with two VPCs and two clusters in one AWS account until the operator maps dedicated accounts.

```text
bootstrap (S3 state)
    → vpc-nonprod → eks-nonprod (MNG system + applications)
    → vpc-prod    → eks-prod    (MNG system + applications)
GitOps hub: Argo CD on eks-nonprod
Destinations: cluster-nonprod, cluster-prod
Artifacts: one ECR set (created with nonprod) promoted by digest
```

Kubernetes add-ons after EKS managed drivers are GitOps-owned. Terraform does not install Argo, Traefik, or Rollouts.

Region default: `us-east-1`.
