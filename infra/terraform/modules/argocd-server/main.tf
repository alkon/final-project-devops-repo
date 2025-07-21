resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name                       = "argocd"
  namespace                  = "argocd"
  create_namespace           = true
  repository                 = "oci://ghcr.io/argoproj/argo-helm"
  chart                      = "argo-cd"
  version                    = "8.1.2"

  # --- Best practice parameters to enable ---
  wait                       = true     #  Wait for all resources to be ready.
  timeout                    = 600      # Give it more time to deploy.
  atomic                     = true     # Rollback on failure.

  # values = [file("${path.module}/values/values.yaml")]

  values = [
    templatefile("${path.module}/values/values.yaml.tpl", {
      argocd_password = var.argocd_password # Pass the Terraform variable to the template
    })
  ]

}

