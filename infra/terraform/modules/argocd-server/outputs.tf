output "argocd_namespace" {
  value = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_server_node_port" {
  description = "The NodePort for the Argo CD server"
  value       = data.kubernetes_service.argocd_server.spec[0].port[0].node_port
}

output "argocd_helm_release_resource" {
  description = "The helm_release resource for Argo CD"
  value       = helm_release.argocd
}
