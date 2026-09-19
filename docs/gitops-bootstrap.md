# GitOps bootstrap

Order after clusters exist:

1. Install Argo CD on `eks-nonprod` (hub, cost-aware)
2. Register destinations `cluster-nonprod` and `cluster-prod`
3. Platform AppProject + add-on ApplicationSets
4. ESO, cert-manager, Traefik, Rollouts, observability, policies
5. Application workloads

Do not create live Applications in this phase. Destination names are the new logical clusters, not disposable legacy names.

Point Argo CD at **your** GitOps and Helm repositories. Do not use this public template as a live source.
