# Tests

There is no live AWS in Phase 09A.

- `scripts/validate.sh` — `terraform fmt` + `init -backend=false` + `validate` per root
- `scripts/naming-audit.sh` — forbidden AWS naming tokens must be zero
- `terraform plan` — skipped until AWS credentials exist; see workspace `docs/aws-greenfield/terraform-plan-review.md`
