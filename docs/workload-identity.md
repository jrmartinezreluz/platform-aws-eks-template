# Workload identity

Default: **EKS Pod Identity**.

IRSA remains an exception when a controller cannot use Pod Identity.

GitOps add-ons that need AWS APIs (ESO, Cluster Autoscaler, optional Load Balancer Controller, Velero) should use Pod Identity associations after Argo exists. Those associations are **PLANNED** (not all encoded in Terraform in this phase except CSI drivers).

Do not create long-lived IAM users for in-cluster secret sync.
