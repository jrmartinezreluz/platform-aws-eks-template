# Version pins (confirmed helm search 2026-09-08)

| Add-on | Owner after bootstrap | Pin |
|--------|------------------------|-----|
| vpc-cni, coredns, kube-proxy, EBS/EFS CSI, snapshot-controller, pod-identity-agent | EKS managed (Terraform) | see environment `addon_versions` |
| Argo CD | Helm on `eks-nonprod` (hub) | chart **10.8.2** / appVersion **v3.5.2** |
| Argo Rollouts | Helm/GitOps | chart **2.43.0** / controller **v1.10.0** |
| External Secrets Operator | Helm/GitOps + IRSA | chart **2.10.0** / appVersion **v2.10.0** |
| cert-manager | Helm/GitOps | chart **v1.21.1** / appVersion **v1.21.1** |
| Traefik | Helm/GitOps | chart **41.5.0** / appVersion **v3.7.13** |
| AWS Load Balancer Controller | **not installed** | Traefik Service NLB is the selected pattern |
| kube-prometheus-stack | Helm/GitOps | chart **90.0.0** / Prometheus Operator **v0.93.1**; Grafana PVC off; retention 7d |
| Cluster Autoscaler | Helm/GitOps + IRSA | chart **9.59.0** / appVersion **1.35.0** (matches Kubernetes 1.35) |
| Kyverno | Helm + IRSA `eks-<cluster>-kyverno` | chart **3.9.1** / appVersion **v1.19.1** |
| Fluent Bit | Helm + IRSA | chart **0.58.2** / app **5.1.2**; platform NS grep includes `kyverno` `velero` |
| Velero | Helm + IRSA `eks-<cluster>-velero` | chart **12.1.0** / app **v1.18.1** / AWS plugin **v1.13.1** |

Logical GitOps destinations:

- `cluster-nonprod` → AWS cluster `eks-nonprod` (Argo secret `cluster-nonprod`, server `https://kubernetes.default.svc`)
- `cluster-prod` → AWS cluster `eks-prod` (private API; register after a path from the hub exists)

Do not register destinations named after the disposable legacy clusters. AppProject `platform` lists explicit destinations; it does not use `server: '*'`.

## Ownership

Terraform owns AWS/bootstrap primitives (VPC, EKS, node groups, EKS managed add-ons, ECR, secret *containers*, IRSA roles).

Helm was used for the 09B Kubernetes add-on bootstrap. GitOps should adopt those releases afterward.

10B NetworkPolicy/PSS (Git, kubectl bootstrap until Argo adopts):

- `network-policies/application/` — future app default-deny contract
- `network-policies/security-validation/` — proof namespace (keep)
- `pss/namespace-default.yaml` — enforce baseline + restricted audit/warn v1.35
- `reliability/` — Traefik/Rollouts PDBs from 10A
- `rollouts/values-prod.yaml` — replicas=2

- `reliability/pdb-traefik.yaml` — both clusters
- `reliability/pdb-argo-rollouts.yaml` — prod only (replicas >= 2)
- `pss/namespace-default.yaml` — PSS audit/warn baseline on `default`

## Identity

Org SCP `p-m8ajqk1n` denies `eks-auth:AssumeRoleForPodIdentity` on node roles. CSI, ESO, Cluster Autoscaler, Fluent Bit, and Kyverno use **IRSA** as the documented compatibility exception. No static IAM users.

10D admission Git: `kyverno/`, `admission-policies/` (audit/enforce/exceptions/tests). Do not default-deny namespace `kyverno`.
