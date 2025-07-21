#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Pass variables from Terraform via stdin and parse with jq
# This is required for the `data "external"` data source to work.
eval "$(jq -r '@sh "CLUSTER_NAME=\(.cluster_name) KUBECONFIG_PATH=\(.kubeconfig_path) HOST_PORT=\(.host_port) CONTAINER_PORT=\(.container_port) PROTOCOL=\(.protocol) NODE_FILTER=\(.node_filter) AGENT_COUNT=\(.agent_count) SERVER_ARGS=\(.server_args)"')"

# --- ALL LOGGING OUTPUT MUST GO TO STDERR (>&2), EXCEPT THE FINAL JSON ---
echo "Checking if k3d cluster '${CLUSTER_NAME}' exists..." >&2

# Define dynamic port mappings from the variables
PORT_MAPPING="${HOST_PORT}:${CONTAINER_PORT}/${PROTOCOL}@${NODE_FILTER}"

echo "Port mapping for app: $PORT_MAPPING" >&2

# Create or start the cluster using k3d
if ! k3d cluster list | grep -q "^${CLUSTER_NAME}"; then
  echo "Creating k3d cluster: ${CLUSTER_NAME}" >&2
  # Redirect k3d's verbose output to stderr
  k3d cluster create "$CLUSTER_NAME" \
    --agents "$AGENT_COUNT" \
    --port "$PORT_MAPPING" \
    --port "30080-30090:30080-30090@server:0" \
    $SERVER_ARGS \
    --wait >&2
else
  echo "Cluster '${CLUSTER_NAME}' already exists. Checking status..." >&2
  STATUS=$(k3d cluster list "$CLUSTER_NAME" | grep "$CLUSTER_NAME" | awk '{print $3}')
  if [[ "$STATUS" == "stopped" ]]; then
    echo "Starting cluster '${CLUSTER_NAME}'..." >&2
    k3d cluster start "$CLUSTER_NAME" >&2
  else
    echo "Cluster '${CLUSTER_NAME}' is already running." >&2
  fi
fi

# Set KUBECONFIG for the script's session
export KUBECONFIG="${KUBECONFIG_PATH}"

# Wait for the API server to be ready with a robust check
echo "Waiting for Kubernetes API server to be ready..." >&2
start_time=$(date +%s)
timeout_seconds=180 # Wait up to 90 seconds
sleep_interval=5   # Check every 5 seconds

while ! kubectl cluster-info &>/dev/null; do
    current_time=$(date +%s)
    if (( current_time - start_time > timeout_seconds )); then
        echo "Error: Timed out waiting for Kubernetes API server to be ready." >&2
        exit 1
    fi
    echo "  - API server not ready yet. Waiting..." >&2
    sleep $sleep_interval
done

echo "Kubernetes API server is ready. The cluster is fully operational." >&2

# OPTIONAL: Remove the 'sleep 5' for faster execution.
# It was added to solve a subtle race condition but may not be needed on your system.
# echo "Waiting 5 seconds for kubeconfig to be fully written..." >&2
# sleep 5

# This is the ONLY thing that should be sent to stdout.
# Terraform will read this JSON and use it to configure the providers.
jq -n --arg name "${CLUSTER_NAME}" --arg kubeconfig "${KUBECONFIG_PATH}" '{ "cluster_name": $name, "kubeconfig_path": $kubeconfig }'