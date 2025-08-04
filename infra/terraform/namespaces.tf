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
