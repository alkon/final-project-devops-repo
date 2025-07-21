resource "null_resource" "app_swap_cleanup_gate" {
  # This resource is always present (count = 1) so it can always be a dependency.
  # Simultaneously, the module whose count goes to 0 will be destroyed.
  count = 1

  triggers = {
    active_app_type = var.use_oci_chart ? "oci" : "git"
  }

  # This 'local-exec' provisioner runs *after* the null_resource is created.
  # By adding a sleep command here, we introduce a delay *after* the previous
  # application's destruction has been initiated, giving ArgoCD time to clean up.
  provisioner "local-exec" {
    command = "echo 'Waiting for previous ArgoCD application deletion to propagate...'; sleep 30"
  }
}

############################################################################################################################
resource "null_resource" "wait_for_argocd_api" {

  provisioner "local-exec" {
    command = <<EOT
    echo "Waiting for argocd-server pod to be Ready using kubectl wait..."

    # Replace 'argocd' with the actual namespace your Argo CD server is deployed in
    # Replace 'app.kubernetes.io/name=argocd-server' with the exact selector for your Argo CD server pod
    kubectl wait --for=condition=ready pod --selector=app.kubernetes.io/name=argocd-server -n argocd --timeout=180s

    if [ $? -eq 0 ]; then
      echo "argocd-server pod is Ready."
    else
      echo "Timed out or failed waiting for argocd-server pod to become Ready." >&2
      exit 1
    fi
    EOT
  }
}

# A special resource to wait for the cert-manager webhook pods to be ready
resource "null_resource" "wait_for_cert_manager_webhook" {
  provisioner "local-exec" {
    # We will use a while loop with a retry logic to wait for the webhook pods.
    # We wait for the pods to exist first, then wait for them to be ready.
    command = <<EOT
      set -e # Exit immediately if a command exits with a non-zero status

      echo "Waiting for cert-manager webhook pods to be created..."
      TIMEOUT=120
      SLEEP_TIME=5
      START_TIME=$(date +%s)
      while true; do
        if kubectl get pods -l app.kubernetes.io/component=webhook -n cert-ns | grep "webhook"; then
          echo "Webhook pods found. Waiting for readiness..."
          # Wait for the pods to be ready (up to 300s as in your original command)
          kubectl wait --for=condition=ready pod --selector=app.kubernetes.io/component=webhook -n cert-ns --timeout=300s
          break
        fi

        CURRENT_TIME=$(date +%s)
        if [ $((CURRENT_TIME - START_TIME)) -ge $TIMEOUT ]; then
          echo "Timeout waiting for webhook pods to appear."
          exit 1
        fi

        echo "Pods not found yet. Retrying in $SLEEP_TIME seconds..."
        sleep $SLEEP_TIME
      done
    EOT
  }

  # Ensure the cert-manager application has been created by ArgoCD before executing kubectl wait
  depends_on = [module.argocd_app_cert_manager]
}









