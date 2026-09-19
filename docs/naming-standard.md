# Naming standard

| Identity | Example |
|----------|---------|
| GitHub repository | `platform-aws-eks` (unchanged) |
| Platform | `eks` |
| Logical GitOps cluster | `cluster-nonprod` / `cluster-prod` |
| AWS EKS name | `eks-nonprod` / `eks-prod` |
| VPC | `vpc-nonprod` / `vpc-prod` |
| Node groups | `system`, `applications` |
| ECR | `hospitality-booking/frontend` |
| Secrets Manager | `apps/<solution>/<environment>/<secret>` |
| Log groups | `/eks/<cluster>/{application,dataplane,host}` |
| State keys | `platform/eks/<role>/<stack>/terraform.tfstate` |

Tags: `Environment`, `Platform=eks`, `Component`, `ManagedBy=terraform`, `Repository=platform-aws-eks`.

Do not encode organization branding in AWS names, tags, paths, or DNS.
