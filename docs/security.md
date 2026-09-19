# Security

- Private subnets for nodes and control-plane ENIs
- Prod API private; nonprod public CIDRs must be restricted
- IMDSv2 required
- Encrypted EBS/EFS, KMS for EKS secrets, S3 SSE-S3 on state, TLS-only state bucket policy
- Secrets Manager containers without values in Git
- GitHub OIDC environment-scoped `sub`
- No bastion, no `0.0.0.0/0` SSH in this stack
- Access entries instead of aws-auth ConfigMap

Public Traefik/NLB exposure is an operator choice after DNS exists.
