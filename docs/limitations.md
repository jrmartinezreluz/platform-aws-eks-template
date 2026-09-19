# Limitations

- Example CIDRs (`10.10.0.0/16`, `10.20.0.0/16`, `10.30.0.0/16`) must be changed if they collide with your networks.
- `terraform validate` without AWS does not replace `terraform plan` in your account.
- Kyverno/Cosign examples require keys and registry allow-lists you generate.
- Regional backup is illustrated; cross-region DR is out of scope.
- Do not treat this repository as certified production-ready for every organization.
