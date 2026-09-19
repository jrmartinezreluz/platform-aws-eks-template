# Application NetworkPolicy contract (10B)

Apply to **application** namespaces only:

```bash
kubectl apply -n <app-namespace> -f gitops/addons/network-policies/application/
```

Do **not** apply default-deny to kube-system, argocd, argo-rollouts, external-secrets, cert-manager, traefik, or monitoring until dependency maps are complete (deferred).

## Files

| File | Purpose |
|------|---------|
| 00-default-deny.yaml | deny all ingress/egress |
| 10-allow-dns.yaml | UDP/TCP 53 to kube-dns in kube-system (not 0.0.0.0/0) |
| 20-allow-ingress-from-traefik.yaml | Traefik namespace → app pods on labeled ports |
| 30-allow-monitoring.yaml | monitoring namespace → metrics port |
| 40-allow-required-egress.yaml | optional AWS VPC CIDR :443 (no FQDN filter) |
| 50-application-dependencies.yaml.example | named DB/cache ports |

Standard Kubernetes NetworkPolicy **cannot** filter by FQDN. Prefer VPC endpoints and explicit CIDR/port.

## Namespace labels (cross-environment)

```text
platform.environment: dev | staging | uat | production
```

Default: cross-environment traffic DENIED (no allow rule). Exceptions must be explicit extra policies.
