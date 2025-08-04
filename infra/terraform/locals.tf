locals {
  otel_namespace_name   = kubernetes_namespace.otel_ns.metadata[0].name
  thanos_namespace_name = kubernetes_namespace.thanos_ns.metadata[0].name
  monitoring_namespace_name = kubernetes_namespace.monitoring.metadata[0].name
  cert_namespace_name = kubernetes_namespace.cert_ns.metadata[0].name
  flask_app_namespace_name = kubernetes_namespace.flask_app_ns.metadata[0].name
  secrets_namespace_name = kubernetes_namespace.secrets_ns.metadata[0].name
  kargo_namespace_name = var.enable_kargo ? kubernetes_namespace.kargo_ns[0].metadata[0].name : null
}