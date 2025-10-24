# InnovateMart Project Bedrock - Deployment & Architecture Guide

## 📋 Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Infrastructure Components](#infrastructure-components)
3. [Deployment Instructions](#deployment-instructions)
4. [Application Access](#application-access)
5. [Developer Read-Only Access](#developer-read-only-access)
6. [Verification & Testing](#verification--testing)
7. [Troubleshooting](#troubleshooting)

---

## 1. Architecture Overview

### High-Level Architecture
```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                                │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    VPC (10.0.0.0/16)                     │   │
│  │                                                           │   │
│  │  ┌──────────────┐              ┌──────────────┐        │   │
│  │  │ Public Subnet │              │ Public Subnet │        │   │
│  │  │  10.0.101.0/24│              │  10.0.102.0/24│        │   │
│  │  │     (AZ-1)    │              │     (AZ-2)    │        │   │
│  │  └───────┬───────┘              └───────┬───────┘        │   │
│  │          │                               │                │   │
│  │          │         NAT Gateway           │                │   │
│  │          └───────────────┬───────────────┘                │   │
│  │                          │                                │   │
│  │  ┌───────────────────────┴────────────────────────────┐  │   │
│  │  │                Private Subnets                      │  │   │
│  │  │  10.0.1.0/24 (AZ-1) | 10.0.2.0/24 (AZ-2)           │  │   │
│  │  │                                                      │  │   │
│  │  │  ┌──────────────────────────────────────────────┐  │  │   │
│  │  │  │         Amazon EKS Cluster                    │  │  │   │
│  │  │  │         (Kubernetes 1.31)                     │  │  │   │
│  │  │  │                                               │  │  │   │
│  │  │  │  ┌─────────────────────────────────────┐    │  │  │   │
│  │  │  │  │   EKS Managed Node Group            │    │  │  │   │
│  │  │  │  │   - 2-4 t3.medium instances         │    │  │  │   │
│  │  │  │  │   - Auto-scaling enabled            │    │  │  │   │
│  │  │  │  └─────────────────────────────────────┘    │  │  │   │
│  │  │  │                                               │  │  │   │
│  │  │  │  ┌─────────────────────────────────────┐    │  │  │   │
│  │  │  │  │   Retail Store Microservices         │    │  │  │   │
│  │  │  │  │   - UI (Frontend)                    │    │  │  │   │
│  │  │  │  │   - Catalog Service (+ MySQL)        │    │  │  │   │
│  │  │  │  │   - Cart Service (+ Redis)           │    │  │  │   │
│  │  │  │  │   - Orders Service (+ PostgreSQL)    │    │  │  │   │
│  │  │  │  │   - Checkout Service                 │    │  │  │   │
│  │  │  │  │   - Assets Service                   │    │  │  │   │
│  │  │  │  └─────────────────────────────────────┘    │  │  │   │
│  │  │  └──────────────────────────────────────────────┘  │  │   │
│  │  └───────────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    IAM Resources                         │   │
│  │  - EKS Cluster Role                                      │   │
│  │  - EKS Node Group Role                                   │   │
│  │  - Developer Read-Only User                              │   │
│  │  - EBS CSI Driver Role (IRSA)                           │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Component Stack
- **Infrastructure**: Terraform (IaC)
- **Orchestration**: Amazon EKS (Kubernetes 1.31)
- **Container Runtime**: containerd
- **Networking**: Amazon VPC CNI
- **Storage**: Amazon EBS CSI Driver
- **CI/CD**: GitHub Actions
- **Application**: Retail Store Sample App (Microservices)

---

## 2. Infrastructure Components

### 2.1 Network Layer
| Component | Configuration | Purpose |
|-----------|--------------|---------|
| **VPC** | 10.0.0.0/16 | Isolated network environment |
| **Public Subnets** | 10.0.101.0/24, 10.0.102.0/24 | Internet-facing resources (NAT Gateway, future ALB) |
| **Private Subnets** | 10.0.1.0/24, 10.0.2.0/24 | EKS worker nodes and pods |
| **Availability Zones** | 2 AZs | High availability |
| **NAT Gateway** | Single NAT (cost-optimized) | Outbound internet for private subnets |

### 2.2 EKS Cluster
| Component | Specification | Details |
|-----------|--------------|---------|
| **Cluster Name** | innovatemart-eks | Production EKS cluster |
| **Kubernetes Version** | 1.31 | Latest stable version |
| **Node Instance Type** | t3.medium | 2 vCPU, 4GB RAM |
| **Node Group Size** | 2-4 nodes | Auto-scaling enabled |
| **Node Disk** | 30GB EBS gp3 | Persistent storage |

### 2.3 EKS Add-ons
| Add-on | Version | Purpose |
|--------|---------|---------|
| **vpc-cni** | v1.18.1 | Pod networking |
| **coredns** | v1.11.1 | DNS resolution |
| **kube-proxy** | v1.30.0 | Network proxy |
| **aws-ebs-csi-driver** | v1.32.0 | Persistent volume support |
| **eks-pod-identity-agent** | v1.3.0 | IAM roles for service accounts |

### 2.4 Application Services
| Service | Replicas | Database | Purpose |
|---------|----------|----------|---------|
| **UI** | 2 | - | Frontend web interface |
| **Catalog** | 2 | MySQL 5.7 | Product catalog management |
| **Cart** | 2 | Redis 7 | Shopping cart |
| **Orders** | 2 | PostgreSQL 16 | Order processing |
| **Checkout** | 2 | - | Checkout flow |
| **Assets** | 2 | - | Static assets |

---

## 3. Deployment Instructions

### 3.1 Prerequisites
```bash
# Required tools
- AWS CLI v2.x
- Terraform >= 1.0
- kubectl v1.30+
- Git

# AWS Account Requirements
- Admin access to AWS account
- S3 bucket for Terraform state (create manually first)
```

### 3.2 Initial Setup

#### Step 1: Clone Repository
```bash
git clone https://github.com/ExcelIhenacho/innovatemart-bedrock.git
cd innovatemart-bedrock
```

#### Step 2: Configure AWS Credentials
```bash
aws configure
# Enter:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region: us-east-1
# - Default output format: json
```

#### Step 3: Create S3 Bucket for Terraform State
```bash
# Replace 'your-unique-bucket-name' with your bucket name
aws s3 mb s3://your-unique-bucket-name --region us-east-1
aws s3api put-bucket-versioning \
  --bucket your-unique-bucket-name \
  --versioning-configuration Status=Enabled
```

#### Step 4: Update Backend Configuration
Edit `terraform/backend.tf`:
```hcl
terraform {
  backend "s3" {
    bucket       = "your-unique-bucket-name"  # <-- UPDATE THIS
    key          = "envs/prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

### 3.3 Deploy Infrastructure

#### Option A: Manual Deployment
```bash
cd terraform

# Initialize Terraform
terraform init

# Review the execution plan
terraform plan

# Apply the configuration
terraform apply

# Get outputs including cluster info
terraform output
```

#### Option B: CI/CD Deployment (Recommended)

1. **Configure GitHub Secrets**
   - Go to: Repository Settings → Secrets and variables → Actions
   - Add secrets:
     - `AWS_ACCESS_KEY_ID`: Your AWS access key
     - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

2. **Trigger Deployment**
   - **Pull Request**: Creates a plan (review changes)
   - **Merge to main**: Automatically applies infrastructure

### 3.4 Deploy Application

#### Configure kubectl
```bash
aws eks update-kubeconfig --region us-east-1 --name innovatemart-eks
kubectl get nodes
```

#### Deploy Retail Store Application
```bash
# Deploy all services
kubectl apply -f k8s/retail-store-app.yaml

# Monitor deployment
kubectl get pods -n retail-store --watch

# Wait for all pods to be ready (may take 5-10 minutes)
kubectl wait --for=condition=ready pod --all -n retail-store --timeout=600s
```

---

## 4. Application Access

### 4.1 Get Application URL

#### Via kubectl
```bash
# Get the LoadBalancer URL
kubectl get svc ui -n retail-store

# Output example:
# NAME   TYPE           CLUSTER-IP      EXTERNAL-IP                          PORT(S)
# ui     LoadBalancer   10.100.123.45   a1b2c3d4...elb.amazonaws.com         80:32000/TCP

# Access the application
echo "Application URL: http://$(kubectl get svc ui -n retail-store -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
```

#### Via AWS Console
1. Navigate to EC2 → Load Balancers
2. Find the LoadBalancer with tag `kubernetes.io/service-name: retail-store/ui`
3. Copy the DNS name
4. Access: `http://<load-balancer-dns>`

### 4.2 Application Features
- Browse product catalog
- Add items to cart
- View shopping cart
- Place orders
- View order history

---

## 5. Developer Read-Only Access

### 5.1 IAM User Details
- **Username**: `innovatemart-dev-readonly`
- **Permissions**: Read-only access to EKS cluster and CloudWatch Logs
- **Kubernetes Role**: `view-only-role` (get, list, watch on all resources)

### 5.2 Retrieve Developer Credentials

#### Get Access Keys (Admin)
```bash
cd terraform

# Get Access Key ID
terraform output -raw developer_access_key_id

# Get Secret Access Key
terraform output -raw developer_secret_access_key
```

### 5.3 Configure Developer Access

#### Developer Setup Instructions
```bash
# 1. Configure AWS CLI with provided credentials
aws configure --profile innovatemart-dev
# Enter provided Access Key ID and Secret Access Key
# Region: us-east-1
# Output format: json

# 2. Update kubeconfig
aws eks update-kubeconfig \
  --region us-east-1 \
  --name innovatemart-eks \
  --profile innovatemart-dev

# 3. Verify access
kubectl get pods -n retail-store
kubectl get nodes
kubectl logs <pod-name> -n retail-store
```

### 5.4 Developer Allowed Commands
```bash
# ✅ Allowed (Read operations)
kubectl get pods -n retail-store
kubectl get deployments -n retail-store
kubectl get services -n retail-store
kubectl describe pod <pod-name> -n retail-store
kubectl logs <pod-name> -n retail-store
kubectl logs -f <pod-name> -n retail-store
kubectl get events -n retail-store

# ❌ Not Allowed (Write operations)
kubectl delete pod <pod-name> -n retail-store
kubectl apply -f manifest.yaml
kubectl scale deployment catalog --replicas=5
kubectl exec -it <pod-name> -- /bin/bash
```

### 5.5 Generate Developer Documentation

Create a file `DEVELOPER_ACCESS.md`:
```markdown
# Developer Access Instructions

## Credentials
- IAM Username: innovatemart-dev-readonly
- Access Key ID: [PROVIDED_SEPARATELY]
- Secret Access Key: [PROVIDED_SEPARATELY]
- AWS Region: us-east-1

## Setup
1. Install AWS CLI: https://aws.amazon.com/cli/
2. Install kubectl: https://kubernetes.io/docs/tasks/tools/
3. Configure AWS CLI:
   ```bash
   aws configure
   ```
4. Update kubeconfig:
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name innovatemart-eks
   ```

## Usage
```bash
# View all pods
kubectl get pods -A

# View retail store application
kubectl get pods -n retail-store

# View logs
kubectl logs <pod-name> -n retail-store

# View services
kubectl get svc -n retail-store
```

## Support
For issues or additional access, contact: devops@innovatemart.com
```

---

## 6. Verification & Testing

### 6.1 Infrastructure Verification
```bash
# Check VPC
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=innovatemart-bedrock"

# Check EKS Cluster
aws eks describe-cluster --name innovatemart-eks --region us-east-1

# Check node groups
aws eks describe-nodegroup \
  --cluster-name innovatemart-eks \
  --nodegroup-name innovatemart-eks-node-group \
  --region us-east-1
```

### 6.2 Kubernetes Verification
```bash
# Cluster info
kubectl cluster-info

# Check nodes
kubectl get nodes -o wide

# Check namespaces
kubectl get namespaces

# Check all pods
kubectl get pods -A

# Check retail-store namespace
kubectl get all -n retail-store
```

### 6.3 Application Health Check
```bash
# Check deployment status
kubectl get deployments -n retail-store

# Check pod health
kubectl get pods -n retail-store -o wide

# Check service endpoints
kubectl get svc -n retail-store

# Test application endpoints
APP_URL=$(kubectl get svc ui -n retail-store -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl -I http://$APP_URL/health
```

### 6.4 Developer Access Verification
```bash
# Switch to developer profile
export AWS_PROFILE=innovatemart-dev

# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name innovatemart-eks

# Test read operations (should succeed)
kubectl get pods -n retail-store

# Test write operations (should fail with permission error)
kubectl delete pod test -n retail-store
# Expected: Error from server (Forbidden)
```

---

## 7. Troubleshooting

### 7.1 Common Issues

#### Issue: Terraform state bucket not found
```bash
# Solution: Create the S3 bucket first
aws s3 mb s3://your-bucket-name --region us-east-1
```

#### Issue: Pods in CrashLoopBackOff
```bash
# Check pod logs
kubectl logs <pod-name> -n retail-store

# Check pod events
kubectl describe pod <pod-name> -n retail-store

# Check resource constraints
kubectl top pods -n retail-store
```

#### Issue: LoadBalancer not getting external IP
```bash
# Check service
kubectl describe svc ui -n retail-store

# Check events
kubectl get events -n retail-store

# Verify VPC tags for subnets
aws ec2 describe-subnets --filters "Name=tag:kubernetes.io/role/elb,Values=1"
```

#### Issue: Developer cannot access cluster
```bash
# Verify IAM user exists
aws iam get-user --user-name innovatemart-dev-readonly

# Check aws-auth ConfigMap
kubectl get configmap aws-auth -n kube-system -o yaml

# Verify ClusterRole and ClusterRoleBinding
kubectl get clusterrole view-only-role
kubectl get clusterrolebinding view-only-binding
```

### 7.2 Useful Commands

#### View all resources
```bash
kubectl get all -A
```

#### Check cluster autoscaler
```bash
kubectl get deployment cluster-autoscaler -n kube-system
```

#### View EKS add-ons
```bash
aws eks list-addons --cluster-name innovatemart-eks --region us-east-1
```

#### Force pod restart
```bash
kubectl rollout restart deployment <deployment-name> -n retail-store
```

### 7.3 Logs and Monitoring

#### Application Logs
```bash
# Stream logs from a pod
kubectl logs -f <pod-name> -n retail-store

# Get logs from all pods in a deployment
kubectl logs -l app=catalog -n retail-store --tail=100

# Get previous pod logs (if pod restarted)
kubectl logs <pod-name> -n retail-store --previous
```

#### Cluster Logs (via CloudWatch)
```bash
# View available log groups
aws logs describe-log-groups --log-group-name-prefix /aws/eks/innovatemart-eks

# Tail logs
aws logs tail /aws/eks/innovatemart-eks/cluster --follow
```

---

## 📧 Support & Contact

For issues, questions, or support:
- **DevOps Team**: devops@innovatemart.com
- **GitHub Issues**: [Create an issue](https://github.com/your-org/innovatemart-bedrock/issues)
- **Documentation**: See README.md in repository root

---

**Document Version**: 1.0  
**Last Updated**: October 24, 2025  
**Maintained By**: InnovateMart DevOps Team from AltSchool Africa

