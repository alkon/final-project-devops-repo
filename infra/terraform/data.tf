# data source to find the external IP of a cluster node
data "kubernetes_nodes" "cluster_node" {
  # This finds the first node in your cluster. You can add a selector if needed.
  depends_on = [data.external.k3d_cluster_bootstrap]
}

data "template_file" "create_k3d_script" {
  # template = file("${path.module}/scripts/create_k3d_cluster.sh.tpl")
  vars = {
    cluster_name = var.k3d_cluster_name
    context_name = var.k3d_context_name
    host_port         = "5000"
    container_port    = "5000"
    node_filter       = "loadbalancer"
    protocol          = "tcp"
    agent_count = 1
    server_args = ""

    argocd_host_port      = "30080"
    argocd_container_port = "30080"

    kubeconfig_path         = "~/.kube/config"
    # kubeconfig_path       = pathexpand("~/.kube/config")
  }
}