# Node groups

Managed Node Groups only. Karpenter is out of scope for this repository.

| Group | Purpose | Nonprod | Prod |
|-------|---------|---------|------|
| `system` | add-ons, tainted `CriticalAddonsOnly` | 2× t3.medium | 2× t3.medium |
| `applications` | workloads | 2× t3.large | 2× t3.large (max 6) |

AMI: Amazon Linux 2023 x86. ARM is not selected until images are confirmed multi-arch.

Launch templates: gp3 encrypted root, IMDSv2 required.

Capacity: ON_DEMAND. Spot is optional for nonprod `applications` via `capacity_type` on the node group object — do not use Spot for prod or for `system`.

Autoscaling: Cluster Autoscaler (GitOps), not Karpenter.
