# EKS

| Cluster | API public | Notes |
|---------|------------|--------|
| `eks-nonprod` | yes, CIDRs **must** be restricted before apply | bootstrap default in tfvars example is a placeholder |
| `eks-prod` | no | private endpoint; operators use SSM / VPN / a controlled network path |

Authentication mode: `API` access entries. Optional `bootstrap_principal_arns` get cluster admin.

Envelope encryption: KMS key `alias/<cluster-name>` for Kubernetes secrets.

Control plane logs: api, audit, authenticator, controllerManager, scheduler.

Managed add-ons: vpc-cni, coredns, kube-proxy, pod-identity-agent, aws-ebs-csi-driver, optional aws-efs-csi-driver, snapshot-controller. Versions empty = EKS default compatible; pin after `describe-addon-versions`. Never `latest`.

Default Kubernetes version input: `1.35` (STANDARD_SUPPORT through 2027-03). Confirm with `describe-cluster-versions` before apply. Do not use 1.33 (extended support as of 2026-09) or default-to-newest 1.36 without add-on soak.
