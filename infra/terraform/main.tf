# --- Module Deployments ---

module "argocd_server" {
  source = "./modules/argocd-server"

  argocd_password = var.argocd_password

  providers = {
    kubernetes = kubernetes
    helm       = helm
    kubectl    = kubectl
  }
}

######################################################################
module "argocd_app_flask_app_oci" {
  count  = var.use_oci_chart ? 1 : 0

  source = "./modules/argocd-app-oci"
  providers = {
    argocd = argocd.main
  }

  depends_on = [
    module.argocd_app_otel_operator,
    module.argocd_app_otel_instrumentation,
    null_resource.wait_for_argocd_api,
    kubernetes_namespace.flask_app_ns,
    null_resource.app_swap_cleanup_gate
  ]

  app_name      = "flask-app"
  app_namespace = local.flask_app_namespace_name

  repo_url = "ghcr.io/alkon" # without 'oci://' prefix
  repo_revision = "1.0.2"
  chart_name = "flask-app"
  image_tag = "1.6.1"

  argocd_project = "flask-app-project"
}
######################################################################
module "argocd_app_flask_app" {
  count  = var.use_oci_chart ? 0 : 1

  source = "./modules/argocd-app"
  providers = {
    argocd = argocd.main
  }

  depends_on = [
    module.argocd_app_otel_operator,
    module.argocd_app_otel_instrumentation,
    null_resource.wait_for_argocd_api,
    kubernetes_namespace.flask_app_ns,
    null_resource.app_swap_cleanup_gate
  ]

  app_name      = "flask-app"
  app_namespace = local.flask_app_namespace_name

  # Default GitHub repo values
  repo_url      = "https://github.com/alkon/terraform-flask-otel-repo.git"
  repo_revision = "HEAD"
  chart_path    = "k8s/helm-charts/flask-app"

  argocd_project = "flask-app-project"
}
######################################################################

module "argocd_app_flask_simulator" {
  source = "./modules/argocd-app"

  providers = {
    argocd = argocd.main
  }

  depends_on = [
    module.argocd_app_flask_app, # Ensure the flask app is up
    null_resource.wait_for_argocd_api,
  ]

  app_name        = "flask-simulator"
  app_namespace   = local.flask_app_namespace_name

  repo_url        = "https://github.com/alkon/app-gitops-manifests-repo.git"
  repo_revision   = "HEAD"

  chart_path      = "platform-apps/flask-simulator"
  argocd_project  = "flask-app-project"
}

######################################################################

module "argocd_app_cert_manager" {
  source = "./modules/argocd-app"

  providers = {
    argocd = argocd.main
  }

  depends_on = [
    module.argocd_server,
    kubernetes_namespace.cert_ns,
    null_resource.wait_for_argocd_api,
  ]

  app_name        = "cert-manager"
  app_namespace   = local.cert_namespace_name

  repo_url        = "https://github.com/alkon/app-gitops-manifests-repo.git"
  repo_revision   = "HEAD"

  chart_path      = "platform-apps/cert-manager"
  argocd_project = "flask-app-project"

}

######################################################################

module "argocd_app_otel_instrumentation" {
  source = "./modules/argocd-app"

  providers = {
    argocd = argocd.main
  }

  depends_on = [
    module.argocd_app_otel_operator,
    module.argocd_app_otel_collector,
    null_resource.wait_for_argocd_api,
    kubernetes_namespace.flask_app_ns
  ]

  app_name      = "otel-instrumentation"
  # Target namespace is the 'flask-app-ns'
  app_namespace = "flask-app-ns"

  repo_url      = "https://github.com/alkon/app-gitops-manifests-repo.git"
  repo_revision = "HEAD"
  chart_path    = "platform-apps/otel-config"
  argocd_project = "flask-app-project"
}

######################################################################

module "argocd_app_otel_operator" {

  source = "./modules/argocd-app"

  providers = {
    argocd = argocd.main
  }

  depends_on = [
    module.argocd_server,
    kubernetes_namespace.otel_ns,
    null_resource.wait_for_argocd_api,
    null_resource.wait_for_cert_manager_webhook
  ]

  app_name        = "otel-operator"
  app_namespace   = local.otel_namespace_name

  repo_url        = "https://github.com/alkon/app-gitops-manifests-repo.git"
  repo_revision   = "HEAD"

  chart_path      = "platform-apps/otel-operator"
  argocd_project = "flask-app-project"
}

######################################################################

module "argocd_app_otel_collector" {

  source = "./modules/argocd-app"

  providers = {
    argocd = argocd.main
  }

  depends_on = [
    module.argocd_server,
    kubernetes_namespace.otel_ns,
  ]

  app_name        = "otel-collector"
  app_namespace   = local.otel_namespace_name

  repo_url        = "https://github.com/alkon/app-gitops-manifests-repo.git"
  repo_revision   = "HEAD"

  chart_path      = "platform-apps/otel-collector"
  argocd_project = "flask-app-project"
}
######################################################################

module "argocd_app_thanos_receiver" {

  source = "./modules/argocd-app"

  providers = {
    argocd = argocd.main
  }

  depends_on = [
    module.argocd_server,
    kubernetes_namespace.thanos_ns,
  ]

  app_name        = "thanos-receiver"
  app_namespace   = local.thanos_namespace_name

  repo_url        = "https://github.com/alkon/app-gitops-manifests-repo.git"
  repo_revision   = "HEAD"

  chart_path      = "platform-apps/thanos-receiver"
  argocd_project = "flask-app-project"
}

#########################################################################

module "argocd_app_thanos_query" {

  source = "./modules/argocd-app"

  providers = {
    argocd = argocd.main
  }

  depends_on = [
    module.argocd_server,
    kubernetes_namespace.thanos_ns,
  ]

  app_name        = "thanos-query"
  app_namespace   = local.thanos_namespace_name

  repo_url        = "https://github.com/alkon/app-gitops-manifests-repo.git"
  repo_revision   = "HEAD"

  chart_path      = "platform-apps/thanos-query"
  argocd_project = "flask-app-project"
}

#############################################################################
module "argocd_app_grafana" {
  source = "./modules/argocd-app"

  providers = {
    argocd = argocd.main
  }

  depends_on = [
    module.argocd_server,
    kubernetes_namespace.thanos_ns,
  ]

  app_name        = "grafana-app"
  app_namespace   = local.monitoring_namespace_name

  repo_url        = "https://github.com/alkon/app-gitops-manifests-repo.git"
  repo_revision   = "HEAD"

  chart_path      = "platform-apps/grafana"
  argocd_project = "flask-app-project"
}


#########################################################################

module "argocd_app_tempo" {
  source = "./modules/argocd-app"

  providers = {
    argocd = argocd.main
  }

  depends_on = [
    module.argocd_server,
    kubernetes_namespace.monitoring,
    module.argocd_app_otel_collector,
    module.argocd_app_grafana
  ]

  app_name        = "tempo-app"
  app_namespace   = local.monitoring_namespace_name

  repo_url        = "https://github.com/alkon/app-gitops-manifests-repo.git"
  repo_revision   = "HEAD"

  chart_path      = "platform-apps/tempo"
  argocd_project = "flask-app-project"
}

#########################################################################

/*
module "argocd_app_fluent_bit" {
  source = "./modules/argocd-app"

  providers = {
    argocd = argocd.main
  }

  depends_on = [
    module.argocd_app_loki,
    # kubernetes_namespace.monitoring
  ]

  app_name        = "fluent-bit-app"
  app_namespace   = local.monitoring_namespace_name

  repo_url        = "https://github.com/alkon/app-gitops-manifests-repo.git"
  repo_revision   = "HEAD"

  chart_path      = "platform-apps/fluent-bit"
  argocd_project = "flask-app-project"
}
*/

#########################################################################

