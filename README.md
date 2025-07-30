# Final Project: DevOps Infrastructure with Argo CD & GitOps

This Terraform project bootstraps a minimal Argo CD setup which in turn manages a full Kubernetes GitOps platform through Helm charts.

## Managed Components

### Terraform Modules
This repo defines and deploys only **two Terraform resources**:
- `argocd_server`: Deploys Argo CD to the cluster via Helm.
- `argocd_app_*`: Creates Argo CD `Application` resources to delegate further deployments to Argo CD.

All other services (e.g., OpenTelemetry, Grafana, Thanos) are managed **by Argo CD** using Helm charts from GitHub or OCI registries.

### Managed Applications via Argo CD:
| Component | Source | Chart Path |
|----------|--------|------------|
| Flask app (GitHub) | `terraform-flask-otel-repo` | `k8s/helm-charts/flask-app` |
| Flask app (OCI) | `ghcr.io/alkon` | `flask-app` |
| OTel operator, collector, instrumentation | `app-gitops-manifests-repo` | `platform-apps/otel-*` |
| Thanos components | `app-gitops-manifests-repo` | `platform-apps/thanos-*` |
| Grafana, Tempo, Cert Manager | `app-gitops-manifests-repo` | respective `platform-apps/` |
| Fluent Bit (optional) | `app-gitops-manifests-repo` | `platform-apps/fluent-bit` |

## Project Flow
```txt
   Terraform ──────────────┐
│
┌─────────────┐ ▼
│ Argo CD │◄──── Deploy
└─────────────┘
│
├─ Watches Helm/Git/OCI charts
└─ Applies all platform components (apps, infra, monitoring, etc.)
```

##  Observability Design Goal: RED + Tracing Correlation

This stack is designed to allow developers to debug performance issues using both:
- **RED metrics** from OpenTelemetry metrics → Thanos → Grafana
- **Span traces** from OpenTelemetry traces → Tempo → Grafana

### Intended Flow

If the Flask app simulates latency via the `/unstable` route:

1.  A spike appears on a RED metrics dashboard in Grafana (e.g. increased duration or error rate).
2.  Clicking that data point should jump directly to the related span trace via **Grafana Exemplars**.
3.  The trace reveals function timing, context, and logs for that exact request.

This pattern helps reduce MTTR (mean time to resolution) in production environments.

### Known Limitation (as of current version)

- Exemplars are **not yet available** because the current Thanos Helm chart version lacks support.
- The OTel Collector is correctly configured to emit exemplars, but the Thanos Receiver does not store them.

### Future Improvement

Upgrade the Thanos Helm chart and apply the [exemplar support PR](https://github.com/thanos-io/thanos/pull/6035) (once stable) to enable exemplar ingestion and enable trace-to-metric correlation in Grafana.
---

## Simulation Logic: Checkout Endpoint
The `/checkout` endpoint simulates **periodic high-latency failure spikes** to test observability tools:

### Normal Mode
- Latency: 50–150 ms
- Error Rate: ~5%

### Peak Mode (every 1–3 minutes)
- Latency: 1800–2500 ms
- Error Rate: ~70%
- Duration: 30 seconds per peak

### Example Logs
```log
[NORMAL MODE] Checkout SUCCESS after 127.83ms
[PEAK MODE] Checkout FAILED (Simulated Error) after 2017.45ms
```


