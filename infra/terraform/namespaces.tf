resource "kubernetes_namespace" "flask_app_ns" {
  metadata {
    name = "flask-app-ns"
  }
}

resource "kubernetes_namespace" "cert_ns" {
  metadata {
    name = "cert-ns"
  }
}

resource "kubernetes_namespace" "secrets_ns" {
  metadata {
    name = "secrets-ns"
  }
}

resource "kubernetes_namespace" "otel_ns" {
  metadata {
    name = "otel-ns"
  }
}

resource "kubernetes_namespace" "thanos_ns" {
  metadata {
    name = "thanos-ns"
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_namespace" "kargo_ns" {
  count = var.enable_kargo ? 1 : 0
  metadata {
    name = var.kargo_namespace
    labels = {
      "app.kubernetes.io/name"       = "kargo"
      "app.kubernetes.io/version"    = "1.6.0"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}
