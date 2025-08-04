# Kargo v1.6 GitOps Environment Management

> 🚀 **Hybrid Approach**: Terraform manages Kargo server, ArgoCD manages configurations  
> ⚡ **Ultra-Loosely Coupled**: Add/remove with single `enable_kargo` flag  
> 🏛️ **GHCR as Source of Truth**: No Git auth needed - pure registry watching

## 📋 Table of Contents
- [Quick Start](#-quick-start)
- [Loose Coupling Design](#-loose-coupling-design)
- [GHCR Registry Benefits](#️-ghcr-registry-as-source-of-truth)
- [Kargo v1.6 Features](#-kargo-v16-cool-features-used)
- [Architecture](#-architecture)
- [Security](#-security)
- [Troubleshooting](#-troubleshooting)

## 🚀 Quick Start

### Prerequisites
- Kubernetes cluster with ArgoCD installed
- Terraform configured for your cluster

### 2-Step Installation (Smart Automation!)

1. **Deploy Everything Automatically**:
```bash
cd infra/terraform
terraform apply -var="enable_kargo=true"
```
**✨ What happens automatically:**
- Installs Kargo v1.6 server in `kargo-ns` 
- Creates `kargo-configs` ArgoCD application
- Deploys all Kargo resources (Project, Warehouse, Stages)
- Sets up GHCR registry watching

2. **Access Kargo UI**:
```bash
kubectl port-forward -n kargo-ns svc/kargo-api 8080:443
# Open: http://localhost:8080
# Login: admin / admin123 (change immediately!)
```

## 🎯 Next Steps After Terraform Deployment

### **1. Verify Kargo Installation**:
```bash
# Check Kargo deployments
kubectl get deployments -n kargo-ns

# Should see: kargo-api, kargo-controller, kargo-webhooks-server (all 1/1 READY)
```

### **2. Verify Kargo Configurations (Auto-Deployed!)**:
```bash
# ✨ No manual step needed! Terraform automatically created the kargo-configs ArgoCD app
# Just verify it's synced in ArgoCD UI
kubectl get application kargo-configs -n argocd
```

### **3. Deploy Environment Applications**:
```bash
# Deploy Kargo-managed ArgoCD applications
kubectl apply -f kargo/argocd-apps/flask-app-dev.yaml
kubectl apply -f kargo/argocd-apps/flask-app-staging.yaml  
kubectl apply -f kargo/argocd-apps/flask-app-prod.yaml
```

### **4. Verify Complete Setup**:
```bash
# Check Kargo resources are created
kubectl get warehouses,stages,projects -n kargo-ns

# Check ArgoCD applications
kubectl get applications -n argocd -l managed-by=kargo

# Verify namespaces created
kubectl get namespaces | grep flask-app
```

### **5. Access Kargo Dashboard**:
```bash
# Start port-forward (run in background)
kubectl port-forward -n kargo-ns svc/kargo-api 8080:443 &

# Open browser to http://localhost:8080
# Login: admin / admin123 (change password immediately!)
```

## 🔮 What to Expect

### **Immediate Results**:
- 🎨 **Kargo UI**: Visual pipeline showing dev → staging → prod
- 📦 **Warehouse**: Watching `ghcr.io/alkon/flask-app` for new images
- 🟢 **Dev Stage**: Ready for auto-promotion
- 🟡 **Staging Stage**: Configured to promote from dev
- 🔴 **Production Stage**: Awaiting manual approval

### **After CI/CD Pushes New Image**:
1. **Warehouse detects** new image in GHCR
2. **Dev auto-promotes** immediately  
3. **Staging promotes** after 30min stability
4. **Production waits** for your manual approval in UI

### **Success Indicators**:
- ✅ All ArgoCD apps show "Synced" and "Healthy"
- ✅ Kargo UI shows green pipeline status
- ✅ No errors in `kubectl get events -n kargo-ns`

## 🔗 Loose Coupling Design

### **✅ Project Works Without Kargo**
```bash
terraform apply  # enable_kargo=false by default
# Your existing project runs perfectly!
```

### **🔧 Add Kargo Anytime**
```bash
terraform apply -var="enable_kargo=true"
# Zero impact on existing setup
```

### **🗑️ Remove Kargo Easily**
```bash
terraform apply -var="enable_kargo=false"
# Clean removal, no traces left
```

### **Key Benefits**:
- ✅ **Zero Dependencies** - Existing files unchanged
- ✅ **Optional Feature** - Disabled by default
- ✅ **No Git Auth** - Registry-only watching
- ✅ **Parallel Operation** - Coexists with current apps
- ✅ **Easy Removal** - Single flag to disable

## 🏛️ GHCR Registry as Source of Truth

### **Why This Approach Wins**

| Traditional GitOps | GHCR-First Kargo |
|-------------------|-------------------|
| 🔐 GitHub tokens needed | ✅ No auth required |
| 📝 Manual Git commits | ✅ Automatic detection |
| ⏰ Polling delays | ✅ Real-time webhooks |
| 🔄 Complex CI/CD | ✅ Simple workflow |
| 🛡️ Write access risks | ✅ Read-only security |

### **Simplified Workflow**
```
┌─────────┐    ┌──────────┐    ┌───────────┐    ┌──────────────┐    ┌─────────┐
│  CI/CD  │───▶│   GHCR   │───▶│   Kargo   │───▶│ values.yaml  │───▶│ ArgoCD  │
│ builds  │    │ registry │    │ detects   │    │   updates    │    │  syncs  │
└─────────┘    └──────────┘    └───────────┘    └──────────────┘    └─────────┘
```

### **How It Works**
1. **CI/CD pushes** → `ghcr.io/alkon/flask-app:1.8.4`
2. **Kargo watches** → GHCR detects new tag  
3. **Auto-promotes** → Updates `kargo/values/dev-values.yaml`
4. **ArgoCD syncs** → Deploys to cluster
5. **Zero manual work** → Complete automation

## 🆕 Kargo v1.6 Cool Features Used

### 🔔 **Webhook Support**
- Real-time updates from GHCR
- Instant promotion (no polling)
- GitHub webhook integration

### 🎨 **Enhanced UI** 
- Custom colors per environment
- Rich metadata & descriptions
- Visual promotion pipeline

### 🚀 **Smart Filtering**
- Performance optimized discovery
- Intelligent caching (1h TTL)
- Artifact retention policies

### 🔐 **Advanced Security**
- Multi-step approval workflows
- Business hours deployment windows
- Security scan gates
- Pull request creation for prod

### 📊 **Parallel Verification**
- Concurrent testing (dev/staging)
- Sequential verification (production)
- Slack/Teams notifications

### 🎯 **Conditional Promotions**
- Health-based promotion gates
- Verification requirements
- Environment-specific policies

## 🏗️ Architecture

### **Directory Structure**
```
kargo/
├── 📋 KARGO_CONFIG.md         # This documentation
├── 🏢 project.yaml            # Project definition
├── 📦 warehouse.yaml          # Artifact watching
├── 🎭 stages/                 # Environment definitions
│   ├── dev.yaml              # Auto-promotes immediately
│   ├── staging.yaml          # Auto-promotes after 30min
│   └── prod.yaml             # Manual approval required
├── ⚙️ values/                 # Environment configurations
│   ├── dev-values.yaml       # Dev overrides (Kargo managed)
│   ├── staging-values.yaml   # Staging overrides (Kargo managed)
│   └── prod-values.yaml      # Prod overrides (Kargo managed)
└── 🚀 argocd-apps/           # ArgoCD applications
    ├── kargo-configs.yaml    # Manages Kargo configurations
    ├── flask-app-dev.yaml
    ├── flask-app-staging.yaml
    └── flask-app-prod.yaml
```

### **Promotion Flow**
```
📦 GHCR Registry
    ↓ (webhook)
🏭 Kargo Warehouse
    ↓ (auto)
🟢 Dev Environment ────────┐
    ↓ (30min delay)        │
🟡 Staging Environment     │ Parallel
    ↓ (manual approval)    │ Operation
🔴 Production Environment  │
                           │
🔵 Your Existing Apps ─────┘
```

### **Environment Comparison**

| Environment | Replicas | Resources | Service | Auto-Promotion | Verification |
|-------------|----------|-----------|---------|----------------|--------------|
| **Dev** | 1 | 50m/64Mi | ClusterIP | ✅ Immediate | Parallel tests |
| **Staging** | 2 | 100m/128Mi | LoadBalancer | ✅ 30min delay | Integration tests |
| **Production** | 3+ | 200m/256Mi | LoadBalancer | ❌ Manual only | Security + Performance |

## 🔐 Security

### **Default Credentials** (⚠️ Change Immediately!)
```bash
# Kargo UI Login
Username: admin
Password: admin123

# Access Command
kubectl port-forward -n kargo-ns svc/kargo-api 8080:443
```

### **Production Hardening Required**
```bash
# 1. Change admin password in Kargo UI
# 2. Generate new JWT signing key
openssl rand -base64 32 | base64

# 3. Update Terraform with new key
terraform apply -var="enable_kargo=true"
```

### **Security Benefits**
- 🔒 **Read-only registry access** - No Git write permissions
- 🛡️ **Reduced attack surface** - No GitHub tokens to manage
- 🔐 **Immutable artifacts** - Promotes actual container images
- 📋 **Audit trail** - All changes tracked in Git history

## 🚨 Important Notes

### **Migration Strategy**
1. **Phase 1**: Deploy alongside existing apps (parallel operation)
2. **Phase 2**: Test promotions in dev/staging environments  
3. **Phase 3**: Gradually shift traffic to Kargo-managed apps
4. **Phase 4**: Remove old apps when confident

### **Rollback Options**
- 🖱️ **UI Rollback**: Use Kargo dashboard to promote previous versions
- 📝 **Manual Rollback**: Edit `kargo/values/*.yaml` files directly
- 🔄 **Git Rollback**: Revert commits in Git history

## 🔍 Troubleshooting

### **Common Issues**

1. **🚫 Promotion Stuck**
```bash
kubectl logs -n kargo-ns -l app.kubernetes.io/name=kargo
```

2. **❌ ArgoCD Not Syncing** 
```bash
kubectl get app -n argocd flask-app-dev-kargo -o yaml
```

3. **👀 Image Not Detected**
```bash
kubectl describe warehouse -n kargo-ns flask-app
```

4. **🔑 Authentication Issues**
```bash
# Check Kargo controller logs
kubectl logs -n kargo-ns deployment/kargo-controller-manager
```

### **Debug Commands**
```bash
# Check Kargo status
kubectl get warehouses,stages,projects -n kargo-ns

# View promotion history
kubectl get promotions -n kargo-ns

# Check ArgoCD app sync status
kubectl get applications -n argocd -l managed-by=kargo
```

## 📚 Further Reading

- 📖 [Kargo Documentation](https://kargo.akuity.io/)
- 🐙 [Kargo GitHub Repository](https://github.com/akuity/kargo) 
- 🔗 [ArgoCD Integration Guide](https://kargo.akuity.io/docs/argocd-integration)
- 🎥 [Kargo v1.6 Release Blog](https://akuity.io/blog/what-s-new-in-kargo-v1-6)

---

**🎯 TL;DR**: Add cutting-edge GitOps promotion to your project with zero dependencies using `terraform apply -var="enable_kargo=true"`