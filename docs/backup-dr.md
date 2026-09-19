# Backup / DR (10E)

| Layer | Mechanism | Status |
|-------|-----------|--------|
| Kubernetes + EBS PVC | Velero 1.18.1 + CSI `ebs-csi-gp3` + S3 | **restore proven** nonprod |
| EFS | AWS EFS automatic backup → `aws/efs/automatic-backup-vault` | ENABLED (no prod path write drill) |
| AWS Backup custom vault / EKS composite | vaults+plans+tagged selections created; jobs empty until tagged EBS | **PARTIAL** |
| Terraform state | S3 versioning | versions listed, no overwrite |
| RDS | none | n/a |

RPO target Kubernetes: 24h daily 05:00 UTC. Measured ns RTO ~53s on recovery-validation (not an app SLO).
