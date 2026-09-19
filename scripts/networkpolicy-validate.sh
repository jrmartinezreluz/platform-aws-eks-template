#!/usr/bin/env bash
# Repeatable NetworkPolicy proofs for namespace security-validation.
# Usage: ./scripts/networkpolicy-validate.sh cluster-nonprod
# Expected after policies.yaml: DNS=PASS allowed=PASS blocked=FAIL https=FAIL
set -euo pipefail
CTX="${1:?kubectl context}"
NS=security-validation

probe() {
  local name="$1"; shift
  if kubectl --context "$CTX" -n "$NS" exec deploy/client -- "$@" >/dev/null 2>&1; then
    echo "$name=PASS"
  else
    echo "$name=FAIL"
  fi
}

echo "CTX=$CTX"
probe DNS nslookup kubernetes.default.svc.cluster.local
probe allowed /agnhost connect "allowed-server.${NS}.svc.cluster.local:8080" --timeout=5s
probe blocked /agnhost connect "blocked-server.${NS}.svc.cluster.local:8080" --timeout=5s
probe https /agnhost connect checkip.amazonaws.com:443 --timeout=5s
