# Observability

Terraform: CloudWatch log groups `/eks/<cluster>/{application,dataplane,host}` plus EKS control-plane log group `/aws/eks/<cluster>/cluster`.

GitOps: kube-prometheus-stack (Grafana persistence off by default in nonprod example).

Tracing (OTLP) is PLANNED. Alert routing to an operator-owned channel is PENDING OPERATOR.
