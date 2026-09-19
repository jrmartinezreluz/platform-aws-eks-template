# Networking

Independent VPCs, 3 AZs, `/16` with `/20` slices:

| Role | VPC CIDR | Public `/20` | Private `/20` | NAT |
|------|----------|--------------|---------------|-----|
| nonprod | `10.10.0.0/16` | indexes 0–2 | indexes 8–10 | single |
| prod | `10.20.0.0/16` | indexes 0–2 | indexes 8–10 | per AZ |

Indexes 3–7 and 11–15 remain free for expansion / TGW.

Do not reuse the disposable legacy `10.0.0.0/16`.

Interface endpoints (ECR, STS, Secrets Manager, logs, EC2, SSM) plus S3 gateway reduce NAT data. Disable with `enable_vpc_endpoints=false` only on a documented cost-conscious profile.

No SSH bastion. Node access: SSM Session Manager on the node instance role.
