# Ingress

Application IngressClass: **Traefik** (portable charts; `ingressClassName` via Helm values).

Traefik Service type LoadBalancer, internal NLB annotation in the GitOps example.

AWS Load Balancer Controller is **optional** for extra ALB/NLB features. Do not hardcode platform vendor in application charts.

Certificates: cert-manager ClusterIssuer `internal-ca` by default. Public ACME requires an approved public zone.
