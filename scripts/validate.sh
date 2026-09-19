#!/usr/bin/env bash
# Format and validate Terraform roots. Does not apply. Does not require AWS credentials
# when using -backend=false.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
terraform fmt -recursive
ROOTS=(
  bootstrap
  environments/nonprod/network
  environments/nonprod/eks
  environments/prod/network
  environments/prod/eks
)
for d in "${ROOTS[@]}"; do
  echo "==> init/validate $d"
  terraform -chdir="$d" init -backend=false -input=false
  terraform -chdir="$d" validate
done
echo "validate: OK"
