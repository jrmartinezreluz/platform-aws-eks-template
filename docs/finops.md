# FinOps

Two profiles (us-east-1, order-of-magnitude USD/month, not a quote):

**Production-grade (this Terraform defaults):** two EKS control planes, prod NAT per AZ, nonprod single NAT, interface endpoints, prod 3× t3.xlarge applications. Expect roughly **USD 1.0k–1.6k/month** before data transfer and RDS.

**Cost-conscious demo:** skip prod until needed, `enable_vpc_endpoints=false`, smaller node sizes, single NAT, shorter log retention. Expect roughly **USD 350–600/month** for nonprod only.

High-cost items: NAT, EKS control planes, prod nodes, interface VPC endpoints.

Ephemeral portfolios: destroy nonprod eks + network states independently; bootstrap and ECR may be retained.
