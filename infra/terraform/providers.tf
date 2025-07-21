terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }

    argocd = {
      source  = "argoproj-labs/argocd"
      version = "~> 7.0"
    }

    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.0"
    }
  }
}

# The Kubernetes provider configuration
provider "kubernetes" {
  config_path    = data.external.k3d_cluster_bootstrap.result.kubeconfig_path
  config_context = "k3d-${data.external.k3d_cluster_bootstrap.result.cluster_name}"
}

# The Helm provider configuration
provider "helm" {
  kubernetes {
    config_path    = data.external.k3d_cluster_bootstrap.result.kubeconfig_path
    config_context = "k3d-${data.external.k3d_cluster_bootstrap.result.cluster_name}"
  }
}

# The Kubectl provider configuration
provider "kubectl" {
  config_path    = data.external.k3d_cluster_bootstrap.result.kubeconfig_path
  config_context = "k3d-${data.external.k3d_cluster_bootstrap.result.cluster_name}"
}

provider "argocd" {
  alias   = "main"

  server_addr = var.argocd_server
  username    = var.argocd_username
  password    = var.argocd_password
  insecure    = var.argocd_insecure
  plain_text  = true # no need in variable for this
  grpc_web    = false
}
