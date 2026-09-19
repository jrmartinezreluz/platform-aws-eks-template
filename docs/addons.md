# Add-ons

See `gitops/addons/`.

EKS managed (Terraform): vpc-cni, coredns, kube-proxy, pod-identity-agent, EBS CSI, optional EFS CSI, snapshot-controller.

GitOps (not applied here): Argo CD, Argo Rollouts (Helm 2.42.0 / controller v1.9.1), ESO, cert-manager, Traefik, optional AWS LB controller, kube-prometheus, Cluster Autoscaler, Velero.

PDB, NetworkPolicy, and Rollouts usage at application layer remain APPLICATION-LEVEL.
