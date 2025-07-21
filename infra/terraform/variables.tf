######  Variables for Flask Application Deployment (passed from CI/CD)
variable "helm_chart_name" {
  description = "The name of the Helm chart for the Flask application."
  type        = string
}

variable "helm_chart_version" {
  description = "The version of the Helm chart for the Flask application."
  type        = string
}

variable "helm_chart_repo" {
  description = "The base OCI repository URL for the Helm chart (e.g., oci://ghcr.io)."
  type        = string
}

variable "docker_image_repo" {
  description = "The base Docker image repository (e.g., ghcr.io)."
  type        = string
}

variable "github_repo_owner" { # <-- Reverted to original name
  description = "The owner of the GitHub repository (e.g., your GitHub username or organization name)."
  type        = string
}

variable "docker_image_tag" { # <-- Reverted to original name
  description = "The version/tag of the Docker image from CI/CD."
  type        = string
}

# Unified Namespace for Flask App deployments
variable "flask_app_namespace" {
  description = "The Kubernetes namespace for the Flask application deployment."
  type        = string
  default     = "flask-app-ns"
}

variable "flask_app_service_name" {
  description = "The OpenTelemetry service name for the Flask application."
  type        = string
  default     = "flask-app-srv"
}

variable "git_repo_name" {
  description = "The name of the Git repository containing the Helm chart."
  type        = string
  default     = "terraform-flask-otel-repo" # Provide a sensible default
}
#############################################################################################################

### K3D -specific
variable "k3d_cluster_name" {
  description = "Name of the k3d cluster"
  type        = string
  default     = "tf-cluster"
}

variable "k3d_context_name" {
  description = "Name of the k3d context"
  type        = string
  default     = "k3d-tf-cluster"
}

variable "k3d_app_port" {
  description = "The host port to map the app to."
  type        = number
  default     = 8080
}

variable "k3d_app_container_port" {
  description = "The container port the app exposes."
  type        = number
  default     = 80
}

variable "enable_namespace_creation" {
  description = "Whether to create the app namespace (disable if it already exists)"
  type        = bool
  default     = true
}

variable "use_local_chart" {
  description = "If true, use a local Helm chart instead of an OCI registry chart"
  type        = bool
  default     = false
}

variable "use_oci_chart" {
  description = "Set to true to source the flask-app Helm chart from an OCI registry, false to source from Git."
  type        = bool
  default     = false # Default to sourcing from Git
}

### Argo CD - specific ########################################################
variable "argocd_host_port" {
  type    = string
  default = "30080"
}

variable "argocd_container_port" {
  type    = string
  default = "30080"
}

variable "argocd_server" {
  type        = string
  default = ""
  sensitive   = true
  description = "Argo CD server address"
}

# variable "argocd_auth_token" {
#   type        = string
#   default = ""
#   sensitive   = true
#   description = "Argo CD auth token"
# }

variable "argocd_username" {
  type        = string
  description = "Argo CD username for authentication."
  default     = "admin"
}

variable "argocd_password" {
  type        = string
  sensitive   = true
  description = "Argo CD password for authentication."
}

variable "argocd_insecure" {
  type        = bool
  default     = true
  description = "Allow insecure connection to Argo CD"
}

variable "enable_argocd_app" {
  type    = bool
  default = false
}
