#!/bin/bash

CRD_NAME="${crd_name}"
TIMEOUT=${timeout_seconds}
INTERVAL=${sleep_interval_seconds}
ELAPSED=0

echo "Waiting for CRD '$CRD_NAME' to be available (timeout: $TIMEOUT s, interval: $INTERVAL s)..."

while ! kubectl get crd "$CRD_NAME" >/dev/null 2>&1; do
  sleep "$INTERVAL"
  ELAPSED=$((ELAPSED + INTERVAL))
  if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
    echo "Timeout waiting for CRD: $CRD_NAME"
    exit 1
  fi
done

echo "CRD '$CRD_NAME' is available."
