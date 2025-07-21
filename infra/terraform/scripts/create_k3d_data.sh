#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Pass variables from Terraform
eval "$(jq -r '@sh "CLUSTER_NAME=\(.cluster_name) KUBECONFIG_PATH=\(.kubeconfig_path)"')"

echo "Checking if k3d cluster '${CLUSTER_NAME}' exists..."

# Create or start the cluster using k3d
if ! k3d cluster list | grep -q "^${CLUSTER_NAME}"; then
  echo "Creating k3d cluster: ${CLUSTER_NAME}"
  k3d cluster create "$CLUSTER_NAME" --wait
else
  echo "Cluster '${CLUSTER_NAME}' already exists. Checking status..."
  STATUS=$(k3d cluster list "$CLUSTER_NAME" | grep "$CLUSTER_NAME" | awk '{print $3}')
  if [[ "$STATUS" == "stopped" ]]; then
    echo "Starting cluster '${CLUSTER_NAME}'..."
    k3d cluster start "$CLUSTER_NAME"
  else
    echo "Cluster '${CLUSTER_NAME}' is already running."
  fi
fi

# Set KUBECONFIG for the session
export KUBECONFIG="${KUBECONFIG_PATH}"

# Wait for the API server to be ready
echo "Waiting for Kubernetes API server to be ready..."
start_time=$(date +%s)
timeout_seconds=90
while ! kubectl cluster-info &>/dev/null; do
    current_time=$(date +%s)
    if (( current_time - start_time > timeout_seconds )); then
        echo "Error: Timed out waiting for Kubernetes API server to be ready." >&2
        exit 1
    fi
    echo "API server not ready yet. Waiting..." >&2
    sleep 5
done

# Output the cluster name and kubeconfig path as JSON
# jq is used to format a simple JSON output for Terraform
jq -n --arg name "${CLUSTER_NAME}" --arg kubeconfig "${KUBECONFIG_PATH}" '{ "cluster_name": $name, "kubeconfig_path": $kubeconfig }'