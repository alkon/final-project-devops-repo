# Kargo-specific Variables

variable "enable_kargo" {
  description = "Enable Kargo deployment - completely optional and loosely coupled"
  type        = bool
  default     = false  # Disabled by default to prove loose coupling
}

variable "kargo_namespace" {
  description = "Kubernetes namespace for Kargo"
  type        = string
  default     = "kargo-ns"
}

variable "kargo_ui_service_type" {
  description = "Service type for Kargo UI (LoadBalancer, ClusterIP, NodePort)"
  type        = string
  default     = "LoadBalancer"
}

variable "enable_kargo_monitoring" {
  description = "Enable monitoring for Kargo"
  type        = bool
  default     = true
}

variable "argocd_target_revision" {
  description = "Git branch/tag for ArgoCD to track"
  type        = string
  default     = "main"  # Override with -var="argocd_target_revision=features/k8s" during development
}

