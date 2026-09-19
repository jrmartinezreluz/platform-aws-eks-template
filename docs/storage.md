# Storage

- EBS CSI managed add-on + IRSA (`AmazonEBSCSIDriverPolicy`; Pod Identity blocked by org SCP)
- gp3 encrypted via node launch templates
- CSI snapshot controller enabled
- EFS optional (`enable_efs`); prod default true for shared site files
- EFS CSI add-on follows `enable_efs`
- NFS SG allows 2049 only from the cluster security group

RDS is **not** provisioned in this repository. ERP and workflow databases are solution-layer: document the contract, create secret containers, load values out of band. Do not put database passwords in Terraform.
