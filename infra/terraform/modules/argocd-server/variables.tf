variable "argocd_password" {
  description = "The initial admin password for ArgoCD."
  type        = string
  sensitive   = true # Mark as sensitive so it's not shown in logs
}