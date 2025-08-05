# Kargo Usage Guide

> **Complete guide to using Kargo v1.6 for GitOps environment promotions**

## Table of Contents
- [Core Concepts](#core-concepts)
- [Key Principles](#key-principles)
- [Configuration Options](#configuration-options)
- [Kargo v1.6 Features](#kargo-v16-new-features)
- [Common Scenarios](#common-scenarios)
- [CLI Commands](#cli-commands)
- [Best Practices](#best-practices)

## Core Concepts

### **1. Warehouse**
The watcher that monitors your artifact sources (container registries, Helm charts, Git repos).

```yaml
# What it does: Watches GHCR for new flask-app images
apiVersion: kargo.akuity.io/v1alpha1
kind: Warehouse
metadata:
  name: flask-app
spec:
  subscriptions:
    - image:
        repoURL: ghcr.io/alkon/flask-app
        semverConstraint: ">=1.8.0"  # Only versions 1.8.0+
```

### **2. Stage**
Represents an environment (dev, staging, prod) with its own promotion rules.

```yaml
# What it does: Defines how dev environment gets updates
apiVersion: kargo.akuity.io/v1alpha1
kind: Stage
metadata:
  name: dev
spec:
  subscriptions:
    warehouse: flask-app  # Gets updates from warehouse
```

### **3. Freight**
An immutable collection of artifacts (images, charts) that moves through stages.

```
Freight #123:
  - Image: ghcr.io/alkon/flask-app:1.8.4
  - Chart: flask-app-1.0.9
  - Commit: abc123
```

### **4. Promotion**
The process of moving Freight from one stage to another.

## Key Principles

### **Progressive Delivery**
```
Warehouse → Dev → Staging → Production
   New       Auto   Delayed    Manual
```

### **Immutable Promotions**
- What you test in dev is EXACTLY what goes to staging
- No rebuilds between environments
- Git commits track every promotion

### **GitOps Native**
- All changes via Git commits
- Full audit trail
- Easy rollbacks

## Configuration Options

### **1. Promotion Timing**

#### **Immediate Auto-Promotion** (Dev)
```yaml
promotionPolicy:
  autoPromotionEnabled: true
```

#### **Delayed Auto-Promotion** (Staging)
```yaml
promotionPolicy:
  autoPromotionEnabled: true
  autoPromotionDelay: 30m  # Wait 30 minutes
```

#### **Manual Promotion** (Production)
```yaml
promotionPolicy:
  autoPromotionEnabled: false  # Requires manual approval
```

### **2. Changing Staging to Manual**
Edit `kargo/stages/staging.yaml`:
```yaml
spec:
  promotionPolicy:
    autoPromotionEnabled: false  # Changed from true
    # autoPromotionDelay: 30m    # Remove or comment out
```

### **3. Health-Based Promotion**
Only promote if the previous stage is healthy:
```yaml
promotionPolicy:
  autoPromotionEnabled: true
  conditions:
    - type: "HealthyFor"
      duration: "10m"  # Must be healthy for 10 minutes
```

### **4. Business Hours Only**
Restrict promotions to business hours:
```yaml
conditions:
  - type: "BusinessHoursOnly"
    schedule: "0 9-17 * * MON-FRI"  # 9 AM - 5 PM, Mon-Fri
```

## Kargo v1.6 New Features

### **1. Webhook Support**

#### **Real-Time Updates from GHCR**
```yaml
subscriptions:
  - image:
      webhook:
        enabled: true
        github:
          repository: "alkon/final-project-devops-repo"
          events: ["push", "release"]
```

**Benefits**:
- Instant detection (no polling delay)
- Reduced API calls
- Real-time promotions

### **2. Parallel Verification**

#### **Run Multiple Tests Concurrently**
```yaml
verification:
  parallel: true  # v1.6 feature!
  steps:
    - name: smoke-tests
      analysisTemplate:
        name: smoke-tests
    - name: performance-tests
      analysisTemplate:
        name: perf-tests
```

**Benefits**:
- Faster feedback
- Concurrent testing
- Reduced promotion time

### **3. Enhanced UI Customization**

#### **Custom Colors & Descriptions**
```yaml
metadata:
  annotations:
    kargo.akuity.io/color: "#4CAF50"  # Green for dev
    kargo.akuity.io/description: "Development - auto-promotes latest"
    kargo.akuity.io/icon: "rocket"
```

**Benefits**:
- Visual pipeline clarity
- Better team communication
- Custom branding

### **4. Advanced Approvals**

#### **Multi-Step Approval Process**
```yaml
promotionPolicy:
  approvals:
    required: true
    approvers:
      - type: "team"
        name: "platform-team"
      - type: "user"
        name: "tech-lead"
    minimumApprovals: 2
    timeout: "24h"
```

**Benefits**:
- Enhanced security
- Compliance requirements
- Audit trail

### **5. Smart Artifact Filtering**

#### **Performance Optimization**
```yaml
subscriptions:
  - image:
      discoveryLimit: 10  # Only keep last 10 versions
      # v1.6: Smart caching
      cacheTTL: "1h"
retention:
  maxArtifacts: 5
  maxAge: "30d"
```

**Benefits**:
- Reduced memory usage
- Faster UI performance
- Automatic cleanup

### **6. Commit Message Templates**

#### **Rich Commit Messages**
```yaml
gitRepoUpdates:
  - commitMessageTemplate: |
      Kargo: Promote {{.ArtifactType}} {{.ArtifactVersion}} to {{.Stage}}
      
      Previous: {{.PreviousVersion}}
      New: {{.ArtifactVersion}}
      Promoted by: {{.PromotedBy}}
      
      Freight ID: {{.FreightID}}
```

**Benefits**:
- Better Git history
- Traceable changes
- Team notifications

### **7. Conditional Promotions**

#### **Advanced Promotion Gates**
```yaml
conditions:
  - type: "VerificationPassed"
    status: "True"
  - type: "SecurityScanPassed"
    status: "True"
  - type: "NoActiveIncidents"
    integrations:
      - pagerduty
```

## Common Scenarios

### **1. Emergency Rollback**
```bash
# List available freight
kubectl get freight -n kargo-ns

# Promote previous version to prod
kubectl promote freight/abc123 --to=prod -n kargo-ns
```

### **2. Skip Staging**
```bash
# Promote directly from dev to prod (emergency)
kubectl promote --from=dev --to=prod -n kargo-ns
```

### **3. Pause Promotions**
```yaml
# Edit stage to pause
spec:
  promotionPolicy:
    paused: true  # Temporarily stop all promotions
```

### **4. Custom Promotion Schedule**
```yaml
# Only promote on Tuesdays at 2 PM
schedule: "0 14 * * TUE"
```

## CLI Commands

### **Basic Commands**
```bash
# View all stages
kubectl get stages -n kargo-ns

# View current freight in each stage
kubectl get stages -n kargo-ns -o wide

# View promotion history
kubectl get promotions -n kargo-ns

# Manually promote
kubectl promote --from=staging --to=prod -n kargo-ns
```

### **Advanced Commands**
```bash
# Check freight details
kubectl describe freight/freight-abc123 -n kargo-ns

# View stage verification status
kubectl get stages prod -n kargo-ns -o jsonpath='{.status.verification}'

# Force refresh warehouse
kubectl annotate warehouse flask-app refresh=true -n kargo-ns
```

## Best Practices

### **1. Version Constraints**
```yaml
# Good: Specific constraints
semverConstraint: ">=1.8.0 <2.0.0"

# Bad: Too broad
semverConstraint: "*"
```

### **2. Verification Strategy**
- **Dev**: Basic smoke tests (fast)
- **Staging**: Full integration tests
- **Prod**: Minimal health checks + monitoring

### **3. Promotion Windows**
```yaml
# Staging: Auto-promote during work hours
autoPromotionDelay: 2h
conditions:
  - type: "BusinessHoursOnly"

# Prod: Manual only, with approval
autoPromotionEnabled: false
```

### **4. Rollback Strategy**
1. Keep last 3 freight versions
2. Test rollback procedures regularly
3. Document rollback commands

### **5. Monitoring**
```yaml
# Enable Prometheus metrics
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
```

## Troubleshooting

### **Promotion Stuck**
```bash
# Check stage status
kubectl describe stage dev -n kargo-ns

# Check freight status
kubectl get freight -n kargo-ns

# Force reconciliation
kubectl annotate stage dev reconcile=true -n kargo-ns
```

### **Webhook Not Working**
```bash
# Check webhook logs
kubectl logs -n kargo-ns deployment/kargo-webhooks-server

# Verify webhook secret
kubectl get secret webhook-secret -n kargo-ns
```

## Integration with This Project

### **How It Works with Your GitOps Setup**
1. **GHCR Integration**: Kargo watches your existing GHCR registry (`ghcr.io/alkon/flask-app`)
2. **ArgoCD Harmony**: Kargo updates git commits → ArgoCD deploys changes
3. **Terraform Management**: Kargo server managed by Terraform with `enable_kargo=true`
4. **Zero Dependencies**: No changes to existing flask-app or CI workflows needed

### **Your Current Flow Enhanced**
```
CI Workflow → GHCR Registry → Kargo Warehouse → Stages (dev/staging/prod) → ArgoCD Apps
```

### **Accessing Kargo UI**
```bash
# Port forward to access UI
kubectl port-forward -n kargo-ns svc/kargo-api 8080:443

# Then open: http://localhost:8080
# Login: admin / admin123 (change immediately!)
```

### **Project-Specific Commands**
```bash
# Check your flask-app pipeline
kubectl get stages -n kargo-ns -l app=flask-app

# View current versions in each environment  
kubectl get stages -n kargo-ns -o custom-columns="STAGE:.metadata.name,VERSION:.status.currentFreight.artifacts[0].image"

# Manual promote to production (emergency)
kubectl promote --from=staging --to=prod -n kargo-ns
```

## Quick Reference Card

| Task | Command/Config |
|------|---------------|
| Make staging manual | `autoPromotionEnabled: false` |
| Change delay | `autoPromotionDelay: 1h` |
| Add approval | `approvals.required: true` |
| Pause promotions | `paused: true` |
| Emergency promote | `kubectl promote --from=dev --to=prod` |
| View pipeline | Access Kargo UI at `:8080` |
| Enable Kargo | `tf apply -var="enable_kargo=true"` |
| Disable Kargo | `tf apply -var="enable_kargo=false"` |

---

**Pro Tip**: Use Kargo UI for visual pipeline management and CLI for automation/emergencies!