#!/usr/bin/env bash
# Scan NEW Terraform and GitOps manifests for forbidden AWS naming tokens.
# Legacy inventory documents live outside this repository and may contain those
# strings when labeled LEGACY.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PATTERN='(^|[^A-Za-z0-9-])(cw|cwpanama|cw-panama|arkhadia|lla|cs1|cs2|cs3)([^A-Za-z0-9-]|$)'
HITS="$(
  find "$ROOT" -type f \( -name '*.tf' -o -name '*.hcl' -o -name '*.yaml' -o -name '*.yml' \) \
    ! -path '*/.terraform/*' \
    -print0 | xargs -0 grep -nEi "$PATTERN" || true
)"
if [[ -n "$HITS" ]]; then
  echo "NEW TARGET VIOLATIONS:"
  echo "$HITS"
  echo
  echo "NEW TARGET VIOLATIONS: $(echo "$HITS" | grep -c .)"
  exit 1
fi
echo "NEW TARGET VIOLATIONS: 0"
