#!/usr/bin/env bash
# Cheap CI checks: NetworkPolicy files exist, no 0.0.0.0/0:53, PSS versions pinned.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NP="$ROOT/gitops/addons/network-policies"
fail=0
for f in application/00-default-deny.yaml application/10-allow-dns.yaml application/20-allow-ingress-from-traefik.yaml application/30-allow-monitoring.yaml; do
  if [[ ! -f "$NP/$f" ]]; then echo "MISSING $f"; fail=1; fi
done
if grep -R "0.0.0.0/0" "$NP/application/10-allow-dns.yaml" >/dev/null; then
  echo "DNS policy must not use 0.0.0.0/0"
  fail=1
fi
if ! grep -q "enforce-version: v1.35" "$ROOT/gitops/addons/pss/namespace-default.yaml"; then
  echo "PSS default namespace missing v1.35 pin"
  fail=1
fi
if [[ $fail -ne 0 ]]; then exit 1; fi
echo "networkpolicy/pss contract checks OK"
