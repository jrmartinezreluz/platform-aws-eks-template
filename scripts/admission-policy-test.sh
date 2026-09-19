#!/usr/bin/env bash
# Offline Kyverno CLI tests for admission-policies (no cluster, no Cosign network).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$HOME/.local/bin:$PATH"
if ! command -v kyverno >/dev/null 2>&1; then
  echo "kyverno CLI required (v1.19.1). Install to ~/.local/bin/kyverno" >&2
  exit 1
fi
kyverno test "$ROOT/gitops/addons/admission-policies/tests"
