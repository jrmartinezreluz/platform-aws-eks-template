#!/usr/bin/env bash
# Live admission matrix in security-validation.
# Usage: REG=... S_DIGEST=... U_DIGEST=... W_DIGEST=... ./scripts/admission-validate.sh cluster-nonprod
set -euo pipefail
CTX="${1:?kubectl context}"
NS=security-validation
: "${REG:?}" "${S_DIGEST:?}" "${U_DIGEST:?}" "${W_DIGEST:?}"

apply_expect() {
  local name="$1" expect="$2"
  kubectl --context "$CTX" -n "$NS" delete pod "$name" --ignore-not-found --wait=false >/dev/null 2>&1 || true
  local out rc
  set +e
  out=$(kubectl --context "$CTX" -n "$NS" apply -f - 2>&1)
  rc=$?
  set -e
  if [[ "$expect" == "ADMIT" ]]; then
    if [[ $rc -eq 0 ]]; then
      echo "$name=ADMIT"
      kubectl --context "$CTX" -n "$NS" delete pod "$name" --ignore-not-found --wait=false >/dev/null 2>&1 || true
    else
      echo "$name=UNEXPECTED_DENY rc=$rc"
      echo "$out" | tail -5
    fi
  else
    if [[ $rc -ne 0 ]]; then
      echo "$name=DENY"
      echo "  msg=$(echo "$out" | tr '\n' ' ' | sed 's/.*denied the request: //' | cut -c1-220)"
    else
      echo "$name=UNEXPECTED_ADMIT"
      kubectl --context "$CTX" -n "$NS" delete pod "$name" --ignore-not-found --wait=false >/dev/null 2>&1 || true
    fi
  fi
}

base_pod() {
  local name="$1" image="$2"
  cat <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${name}
  namespace: ${NS}
  labels:
    app.kubernetes.io/name: admission-test
    platform.example/phase: "10D"
spec:
  restartPolicy: Never
  automountServiceAccountToken: false
  securityContext:
    runAsNonRoot: true
    runAsUser: 65532
    runAsGroup: 65532
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: app
      image: ${image}
      command: ["/agnhost", "pause"]
      securityContext:
        allowPrivilegeEscalation: false
        privileged: false
        readOnlyRootFilesystem: true
        runAsNonRoot: true
        runAsUser: 65532
        capabilities:
          drop: ["ALL"]
      resources:
        requests:
          cpu: 10m
          memory: 16Mi
        limits:
          memory: 32Mi
EOF
}

echo "CTX=$CTX"
base_pod sc-signed-ok "${REG}@${S_DIGEST}" | apply_expect sc-signed-ok ADMIT
base_pod sc-unsigned "${REG}@${U_DIGEST}" | apply_expect sc-unsigned DENY
base_pod sc-wrong-signer "${REG}@${W_DIGEST}" | apply_expect sc-wrong-signer DENY
base_pod sc-mutable-tag "${REG}:sha-10d-unsigned-b" | apply_expect sc-mutable-tag DENY
base_pod sc-latest "${REG}:latest" | apply_expect sc-latest DENY
base_pod sc-unapproved "docker.io/library/busybox@sha256:c230832bd3b0be59a6a47c729ee0944f07c64883ca2dd818486fb70f86ed00b6" | apply_expect sc-unapproved DENY

apply_expect sc-privileged DENY <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: sc-privileged
  namespace: ${NS}
  labels:
    app.kubernetes.io/name: admission-test
spec:
  restartPolicy: Never
  containers:
    - name: app
      image: ${REG}@${S_DIGEST}
      command: ["/agnhost", "pause"]
      securityContext:
        privileged: true
        allowPrivilegeEscalation: true
EOF

apply_expect sc-hostpath DENY <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: sc-hostpath
  namespace: ${NS}
  labels:
    app.kubernetes.io/name: admission-test
spec:
  restartPolicy: Never
  automountServiceAccountToken: false
  securityContext:
    runAsNonRoot: true
    runAsUser: 65532
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: app
      image: ${REG}@${S_DIGEST}
      command: ["/agnhost", "pause"]
      securityContext:
        allowPrivilegeEscalation: false
        privileged: false
        runAsNonRoot: true
        runAsUser: 65532
        capabilities:
          drop: ["ALL"]
      volumeMounts:
        - name: host
          mountPath: /host
  volumes:
    - name: host
      hostPath:
        path: /etc
EOF
