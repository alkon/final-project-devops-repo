variable "app_name" {
  type        = string
  description = "The name of the ArgoCD Application resource."
}

variable "app_namespace" {
  type        = string
  description = "The target Kubernetes namespace where the application resources will be deployed."
}

variable "repo_url" {
  type        = string
  description = "The URL of the Git repository containing the application manifests."
}

variable "repo_revision" {
  type        = string
  default     = "HEAD"
  description = "The revision (branch, tag, or commit hash) of the Git repository to sync."
}

# variable "chart_path" {
#   type        = string
#   description = "The path within the Git repository to the application's Helm chart or manifests."
# }

variable "argocd_project" {
  type    = string
  default = "default" # Or define a project for each type of app
  description = "The ArgoCD Project the application belongs to."
}

### For OCI Registry as SOT (Source-Of-Truth) support
variable "image_tag" {
  description = "The Docker image tag to be deployed via Helm values"
  type        = string
  default     = ""
}

variable "chart_name" {
  description = "Helm chart name to deploy"
  type        = string
  default     = null
}

variable "chart_version" {
  description = "The Helm chart version (used when deploying from OCI)"
  type        = string
  default     = null
}
###