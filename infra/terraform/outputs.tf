output "kube_context" {
  value = "k3d-${var.k3d_cluster_name}"
}

# output "flask_app_manifest_yaml" {
#   value = module.argocd.flask_app_manifest_yaml
# }
