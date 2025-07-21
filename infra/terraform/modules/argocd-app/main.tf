
resource "argocd_application" "this" {

  # provider = argocd.main

  # Renamed from "flask_app" to "this" for generic modules
  metadata {
    name = var.app_name     # Uses new generic variable
    namespace = "argocd"         # ArgoCD Application CRDs typically live in the ArgoCD namespace
    labels = {
      "app.kubernetes.io/managed-by" = "Terraform"
      "app.kubernetes.io/name"       = var.app_name
    }
  }

  spec {
    # project = var.argocd_project # Use a variable for project, default to "default"

    source {
      # repo_url        = var.repo_url
      # target_revision = var.repo_revision
      # path            = var.chart_path

      repo_url        = var.repo_url
      target_revision = var.repo_revision
      path            = var.chart_path
      chart           = var.chart_name

      # helm {
      #   value_files = var.app_name == "flask-app" ? ["values.yaml"] : []
      #   parameter {
      #     name  = "image.tag"
      #     value = var.app_name == "flask-app" ? var.image_tag : ""
      #   }
      # }



    }

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = var.app_namespace # Uses new generic variable
    }

    sync_policy {
      automated {
        prune       = true
        self_heal   = true
        allow_empty = false
      }
      sync_options = [
        "CreateNamespace=false", # Automatically creates the target namespace if it doesn't exist
        "ApplyOutOfSyncOnly=true" # Only applies changes to out-of-sync resources
      ]
    }

    # Prevent syncOut for minor diffs in the 'spec.selector' field block of the Instrumentation CR
    # platforms-apps/otel-config/instrumentation.yaml
    ignore_difference {
      group = "opentelemetry.io"
      kind  = "Instrumentation"
      name  = "flask-app-instrumentation"
      namespace = var.app_namespace

      json_pointers = [
        "/spec/selector"
      ]
    }

  }
}

