# This data source executes a shell script to create/start the k3d cluster.
data "external" "k3d_cluster_bootstrap" {
  program = ["/bin/bash", "${path.module}/scripts/create_k3d_cluster.sh.tpl"]

  # These variables are passed as a JSON object to the script's stdin.
  # The script uses 'jq' to parse them.
  query = {
    cluster_name    = var.k3d_cluster_name
    host_port       = var.k3d_app_port
    container_port  = var.k3d_app_container_port
    protocol        = "tcp"
    node_filter     = "server:0"
    agent_count     = 0 # We are creating a single-node cluster
    server_args     = "" # Optional: add extra args here if needed

    kubeconfig_path = pathexpand("~/.kube/config")
  }
}