# Kargo Server v1.6 Installation 
# Manages the Kargo server installation via Helm
# Completely optional and loosely coupled from existing project
# Note: Namespace is defined in namespaces.tf following project patterns

# Kargo Server Helm Release (v1.6 with webhook support)
resource "helm_release" "kargo" {
  count = var.enable_kargo ? 1 : 0
  name       = "kargo"
  repository = "oci://ghcr.io/akuity/kargo-charts"
  chart      = "kargo"
  version    = "1.6.0"
  namespace  = local.kargo_namespace_name

  # Wait for deployment to be ready
  wait          = true
  wait_for_jobs = true
  timeout       = 600
  
  # Easy cleanup configuration
  cleanup_on_fail = true
  force_update    = false
  disable_webhooks = false

  # Kargo v1.6 Configuration with cool features
  values = [
    yamlencode({
      # Enable webhook support (v1.6 feature)
      webhook = {
        enabled = true
        service = {
          type = "ClusterIP"
          port = 9443
        }
      }

      # Enhanced UI (v1.6 feature)
      ui = {
        enabled = true
        service = {
          type = "LoadBalancer"  # Change to ClusterIP if you prefer port-forward
          port = 8080
        }
      }

      # API Server configuration
      api = {
        service = {
          type = "ClusterIP"
          port = 8080
        }
        # Enable RBAC integration
        rbac = {
          installClusterRoles = true
        }
        # Admin account configuration (required in v1.6)
        adminAccount = {
          # Default password: "admin123" (change after installation)
          passwordHash = "$2a$10$Zrhhie4vLZaNgGvqTzm/G.7fq9T/Q1HqGV8vCmMo42aO3TmfV6/Lu"
          # Token signing key for JWT tokens (base64 encoded)
          tokenSigningKey = "dGhpc2lzYXNlY3JldGtleWZvcmthcmdvand0dG9rZW5zaWduaW5n"
          enabled = true
        }
      }

      # Improved artifact filtering (v1.6)
      controller = {
        # Enhanced performance for large-scale deployments
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
        # Artifact filtering optimization
        artifactFilter = {
          enabled = true
          # Smart filtering for better performance
          maxAge = "30d"
          # Concurrent processing
          workers = 5
        }
      }

      # Security enhancements
      security = {
        # Pod security context
        podSecurityContext = {
          runAsNonRoot = true
          runAsUser    = 1000
          fsGroup      = 1000
        }
      }

      # Monitoring integration
      monitoring = {
        enabled = true
        serviceMonitor = {
          enabled = true
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.kargo_ns]
}

# Git credentials removed - not needed for registry-watching approach

# RBAC for Kargo to manage ArgoCD applications
resource "kubernetes_cluster_role" "kargo_argocd" {
  metadata {
    name = "kargo-argocd-access"
  }

  rule {
    api_groups = ["argoproj.io"]
    resources  = ["applications", "appprojects"]
    verbs      = ["get", "list", "watch", "update", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets", "configmaps"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }

  rule {
    api_groups = ["kargo.akuity.io"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_cluster_role_binding" "kargo_argocd" {
  metadata {
    name = "kargo-argocd-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.kargo_argocd.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "kargo-controller-manager"
    namespace = var.enable_kargo ? local.kargo_namespace_name : var.kargo_namespace
  }
}

# Wait for Kargo to be ready
resource "null_resource" "wait_for_kargo" {
  count = var.enable_kargo ? 1 : 0
  depends_on = [helm_release.kargo]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for Kargo deployments to be ready..."
      kubectl wait --for=condition=Available deployment/kargo-api \
        -n ${local.kargo_namespace_name} \
        --timeout=300s --kubeconfig=${data.external.k3d_cluster_bootstrap.result.kubeconfig_path}
      kubectl wait --for=condition=Available deployment/kargo-controller \
        -n ${local.kargo_namespace_name} \
        --timeout=300s --kubeconfig=${data.external.k3d_cluster_bootstrap.result.kubeconfig_path}
      echo "✅ Kargo v1.6 is ready!"
    EOT
  }
}

# ArgoCD Application to manage Kargo configurations (Smart Automation!)
resource "kubectl_manifest" "kargo_configs_app" {
  count = var.enable_kargo ? 1 : 0
  depends_on = [null_resource.wait_for_kargo]

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "kargo-configs"
      namespace = "argocd"
      labels = {
        "app.kubernetes.io/name"       = "kargo-configs"
        "app.kubernetes.io/managed-by" = "terraform"
        "managed-by"                   = "kargo"
      }
      annotations = {
        "kargo.akuity.io/dashboard" = "http://localhost:8080"
      }
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/${var.github_repo_owner}/final-project-devops-repo.git"
        targetRevision = var.argocd_target_revision
        path           = "kargo"
        directory = {
          include = "project.yaml\nwarehouse.yaml\nstages/*.yaml"
          exclude = "argocd-apps/**\nKARGO_CONFIG.md"
        }
      }
      destination = {
        server = "https://kubernetes.default.svc"
      }
      syncPolicy = {
        automated = {
          prune      = true
          selfHeal   = true
          allowEmpty = false
        }
        syncOptions = [
          "CreateNamespace=true",
          "ApplyOutOfSyncOnly=true"
        ]
        retry = {
          limit = 5
          backoff = {
            duration    = "5s"
            factor      = 2
            maxDuration = "3m"
          }
        }
      }
      ignoreDifferences = [
        {
          group = "kargo.akuity.io"
          kind  = "Stage"
          jsonPointers = ["/status"]
        },
        {
          group = "kargo.akuity.io"
          kind  = "Warehouse"
          jsonPointers = ["/status", "/spec/subscriptions/*/discoveredArtifacts"]
        }
      ]
    }
  })
}

# Output Kargo UI access information
output "kargo_ui_service" {
  description = "Kargo UI service information"
  value = var.enable_kargo ? {
    namespace    = local.kargo_namespace_name
    service_name = "kargo-api"
    port         = 443
    access_cmd   = "kubectl port-forward -n ${local.kargo_namespace_name} svc/kargo-api 8080:443"
    ui_url       = "http://localhost:8080"
    credentials  = "admin / admin123 (change immediately!)"
  } : null
}

# Cleanup script for easy Kargo removal
resource "null_resource" "kargo_cleanup" {
  count = var.enable_kargo ? 0 : 1  # Only runs when disabling Kargo
  
  provisioner "local-exec" {
    command = "${path.module}/scripts/cleanup_kargo.sh ${data.external.k3d_cluster_bootstrap.result.kubeconfig_path}"
  }
  
  triggers = {
    # Run cleanup when enable_kargo changes from true to false
    enable_kargo = var.enable_kargo
  }
}