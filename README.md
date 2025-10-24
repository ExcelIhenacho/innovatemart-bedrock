# 🚀 InnovateMart – Project Bedrock

[![Terraform](https://img.shields.io/badge/Terraform-≥1.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.31-326CE5?logo=kubernetes)](https://kubernetes.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazon-aws)](https://aws.amazon.com/eks/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Deploy the **Retail Store Sample App** to a production-grade **Amazon EKS** cluster using **Infrastructure as Code (Terraform)** and a fully automated **CI/CD pipeline (GitHub Actions)**.

---

## 📋 Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Deployment Options](#deployment-options)
- [CI/CD Pipeline](#cicd-pipeline)
- [Developer Access](#developer-access)
- [Bonus Features](#bonus-features)
- [Project Structure](#project-structure)
- [Documentation](#documentation)
- [Cleanup](#cleanup)
- [Contributing](#contributing)
- [License](#license)

---

## 📝 Overview

**InnovateMart's Project Bedrock** is a complete end-to-end solution for deploying a microservices-based retail application on AWS. This project demonstrates DevOps best practices including:

✅ **Infrastructure as Code** with Terraform  
✅ **Container Orchestration** with Amazon EKS  
✅ **Automated CI/CD** with GitHub Actions  
✅ **Secure RBAC** with read-only developer access  
✅ **Managed AWS Services** (RDS, DynamoDB)  
✅ **Advanced Networking** (ALB, Ingress)  
✅ **Production-Ready** configurations

---

## 🏗️ Architecture

### High-Level Architecture
```
┌─────────────────────────────────────────────────────────┐
│                      AWS Cloud                           │
│                                                           │
│  ┌─────────────────────────────────────────────────┐   │
│  │              VPC (10.0.0.0/16)                   │   │
│  │                                                   │   │
│  │  Public Subnets (2 AZs)    Private Subnets      │   │
│  │  ├─ NAT Gateway            ├─ EKS Worker Nodes  │   │
│  │  └─ Load Balancer          ├─ Application Pods  │   │
│  │                             └─ RDS Instances     │   │
│  └─────────────────────────────────────────────────┘   │
│                                                           │
│  ┌─────────────────────────────────────────────────┐   │
│  │         Amazon EKS Cluster (Kubernetes 1.31)     │   │
│  │  ┌─────────────────────────────────────────┐    │   │
│  │  │  Retail Store Microservices              │    │   │
│  │  │  ├─ UI (Frontend)                        │    │   │
│  │  │  ├─ Catalog Service → RDS MySQL          │    │   │
│  │  │  ├─ Cart Service → DynamoDB              │    │   │
│  │  │  ├─ Orders Service → RDS PostgreSQL      │    │   │
│  │  │  ├─ Checkout Service                     │    │   │
│  │  │  └─ Assets Service                       │    │   │
│  │  └─────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### Technology Stack
- **IaC**: Terraform ≥ 1.0
- **Orchestration**: Amazon EKS 1.31
- **Compute**: EC2 t3.medium (2-4 nodes)
- **Storage**: EBS CSI Driver + Amazon RDS + DynamoDB
- **Networking**: VPC CNI, AWS Load Balancer Controller
- **CI/CD**: GitHub Actions
- **Application**: AWS Retail Store Sample App

---

## ✨ Features

### Core Features (Required)
- [x] **VPC with Multi-AZ** - 2 public & 2 private subnets
- [x] **Amazon EKS Cluster** - Kubernetes 1.31 with managed node groups
- [x] **IAM Roles & Policies** - Least privilege security model
- [x] **Retail Store App Deployment** - Full microservices stack
- [x] **Read-Only Developer Access** - IAM user with Kubernetes RBAC
- [x] **CI/CD Pipeline** - Automated Terraform deployment
- [x] **EKS Add-ons** - VPC CNI, CoreDNS, kube-proxy, EBS CSI

### Bonus Features (Extra Credit)
- [x] **Managed Databases**
  - AWS RDS PostgreSQL (Orders Service)
  - AWS RDS MySQL (Catalog Service)
  - Amazon DynamoDB (Cart Service)
- [x] **Advanced Networking**
  - AWS Load Balancer Controller
  - Kubernetes Ingress with ALB
  - SSL/TLS Support (ACM ready)
  - Route53 Integration (documentation)

---

## 🔑 Prerequisites

### Required Tools
```bash
# AWS CLI v2
aws --version  # Should be 2.x+

# Terraform
terraform version  # Should be ≥ 1.0

# kubectl
kubectl version --client  # Should be v1.30+

# Git
git --version
```

### AWS Account Setup
1. **AWS Account** with administrative access
2. **AWS CLI** configured with credentials:
   ```bash
   aws configure
   # Enter: Access Key, Secret Key, Region (us-east-1), Output (json)
   ```
3. **S3 Bucket** for Terraform state (create before deployment)

---

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/ExcelIhenacho/innovatemart-bedrock.git
cd innovatemart-bedrock
```

### 2. Create S3 Bucket for Terraform State
```bash
# Replace with your unique bucket name
BUCKET_NAME="your-terraform-state-bucket"

aws s3 mb s3://${BUCKET_NAME} --region us-east-1
aws s3api put-bucket-versioning \
  --bucket ${BUCKET_NAME} \
  --versioning-configuration Status=Enabled
```

### 3. Update Backend Configuration
Edit `terraform/backend.tf` and replace the bucket name:
```hcl
terraform {
  backend "s3" {
    bucket       = "your-terraform-state-bucket"  # <-- UPDATE THIS
    key          = "envs/prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

### 4. Deploy Infrastructure
```bash
cd terraform

# Initialize Terraform
terraform init

# Review execution plan
terraform plan

# Apply configuration
terraform apply

# Wait ~15-20 minutes for EKS cluster to be ready
```

### 5. Configure kubectl
```bash
aws eks update-kubeconfig --region us-east-1 --name innovatemart-eks
kubectl get nodes
```

### 6. Deploy Application

**Option A: Basic Deployment (In-Cluster Databases)**
```bash
kubectl apply -f k8s/retail-store-app.yaml
```

**Option B: Managed Databases (BONUS)**
```bash
kubectl apply -f k8s/retail-store-managed-db.yaml
```

**Option C: With Ingress/ALB (BONUS)**
```bash
kubectl apply -f k8s/retail-store-managed-db.yaml
kubectl apply -f k8s/ingress-alb.yaml
```

### 7. Access the Application
```bash
# Get LoadBalancer URL
kubectl get svc ui -n retail-store

# Or use this command to get the URL
echo "http://$(kubectl get svc ui -n retail-store -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

# Wait 2-3 minutes for LoadBalancer to provision, then open in browser
```

---

## 🔄 CI/CD Pipeline

### GitHub Actions Workflows

#### 1. **Terraform Infrastructure Pipeline**
**File**: `.github/workflows/terraform.yml`

**Triggers**:
- **Pull Request** → Runs `terraform plan` and comments results
- **Push to main** → Runs `terraform apply` automatically

**Setup**:
1. Go to: **Repository Settings** → **Secrets and variables** → **Actions**
2. Add secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

#### 2. **Application Deployment Pipeline**
**File**: `.github/workflows/deploy-app.yml`

**Triggers**:
- Manual workflow dispatch
- Push to main (on k8s/ changes)

**Features**:
- Automated kubectl configuration
- Application deployment
- Health checks
- Deployment summary

### Branching Strategy
```
main (production)
  ↑
  │ PR + terraform plan
  │
feature/* branches (development)
```

**Workflow**:
1. Create feature branch: `git checkout -b feature/my-feature`
2. Make changes and push
3. Create Pull Request → CI runs `terraform plan`
4. Review plan in PR comments
5. Merge to main → CI runs `terraform apply`

---

## 👥 Developer Access

### IAM User: `innovatemart-dev-readonly`

**Permissions**:
- ✅ View EKS cluster information
- ✅ View pods, deployments, services
- ✅ Read logs
- ✅ Describe resources
- ❌ Create, update, or delete resources

### Setup Instructions for Developers

#### 1. Get Credentials (Admin)
```bash
cd terraform

# Get Access Key ID
terraform output -raw developer_access_key_id

# Get Secret Access Key  
terraform output -raw developer_secret_access_key
```

#### 2. Configure AWS CLI (Developer)
```bash
aws configure --profile innovatemart-dev
# Enter the provided credentials
# Region: us-east-1
# Output: json
```

#### 3. Update kubeconfig (Developer)
```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name innovatemart-eks \
  --profile innovatemart-dev
```

#### 4. Verify Access (Developer)
```bash
# ✅ Allowed commands
kubectl get pods -n retail-store
kubectl get deployments -n retail-store
kubectl logs <pod-name> -n retail-store
kubectl describe pod <pod-name> -n retail-store

# ❌ Denied commands  
kubectl delete pod <pod-name> -n retail-store
kubectl apply -f manifest.yaml
```

---

## 🎯 Bonus Features

### 1. Managed Databases

#### RDS PostgreSQL (Orders Service)
- **Instance**: db.t3.micro
- **Engine**: PostgreSQL 16.3
- **Storage**: 20GB (auto-scaling to 100GB)
- **Encryption**: Enabled
- **Backups**: 7-day retention

#### RDS MySQL (Catalog Service)
- **Instance**: db.t3.micro
- **Engine**: MySQL 8.0.35
- **Storage**: 20GB (auto-scaling to 100GB)
- **Encryption**: Enabled
- **Backups**: 7-day retention

#### DynamoDB (Cart Service)
- **Billing**: Pay-per-request
- **Encryption**: Server-side enabled
- **Backups**: Point-in-time recovery
- **GSI**: customerId-index

**Deploy with managed databases**:
```bash
# Terraform creates databases, secrets, and service accounts
terraform apply

# Deploy application using managed databases
kubectl apply -f k8s/retail-store-managed-db.yaml
```

### 2. Advanced Networking

#### AWS Load Balancer Controller
- Automatic ALB provisioning
- IP-based target mode
- Health check configuration
- SSL/TLS termination support

#### Deploy Ingress
```bash
# Deploy application first
kubectl apply -f k8s/retail-store-managed-db.yaml

# Deploy Ingress (creates ALB)
kubectl apply -f k8s/ingress-alb.yaml

# Get ALB URL
kubectl get ingress -n retail-store
```

#### SSL/TLS Configuration (Optional)
1. Register domain (Route53 or external)
2. Uncomment ACM certificate code in `terraform/alb-controller.tf`
3. Update domain variable
4. Apply terraform
5. Update `k8s/ingress-alb.yaml` with certificate ARN
6. Deploy ingress

---

## 📂 Project Structure

```
innovatemart-bedrock/
│
├── .github/
│   └── workflows/
│       ├── terraform.yml          # Infrastructure CI/CD
│       └── deploy-app.yml         # Application deployment
│
├── terraform/
│   ├── versions.tf                # Provider versions
│   ├── providers.tf               # Provider configurations
│   ├── backend.tf                 # S3 backend config
│   ├── variables.tf               # Input variables
│   ├── vpc.tf                     # VPC and networking
│   ├── eks.tf                     # EKS cluster
│   ├── addons.tf                  # EKS add-ons
│   ├── iam.tf                     # IAM users and roles
│   ├── rds.tf                     # RDS databases (BONUS)
│   ├── dynamodb.tf                # DynamoDB table (BONUS)
│   ├── alb-controller.tf          # ALB Controller (BONUS)
│   └── outputs.tf                 # Output values
│
├── k8s/
│   ├── namespace.yaml             # Kubernetes namespace
│   ├── retail-store-app.yaml      # Basic deployment
│   ├── retail-store-managed-db.yaml  # With managed databases (BONUS)
│   └── ingress-alb.yaml           # ALB Ingress (BONUS)
│
├── docs/
│   └── DEPLOYMENT_GUIDE.md        # Comprehensive guide
│
└── README.md                      # This file
```

---

## 📚 Documentation

- **[Deployment & Architecture Guide](docs/DEPLOYMENT_GUIDE.md)** - Comprehensive deployment instructions, architecture details, and troubleshooting
- **[Retail Store Sample App](https://github.com/aws-containers/retail-store-sample-app)** - Original application repository

---

## 🗑️ Cleanup

### Destroy All Resources
```bash
# Delete Kubernetes resources first
kubectl delete -f k8s/ --all

# Wait for LoadBalancers to be deleted (~2 minutes)
sleep 120

# Destroy Terraform infrastructure
cd terraform
terraform destroy

# Optionally delete S3 backend bucket
aws s3 rb s3://your-terraform-state-bucket --force
```

**⚠️ Warning**: This will delete all resources including databases. Make sure to backup any important data first.

---

## 🧪 Testing & Verification

### Infrastructure Verification
```bash
# Check cluster status
aws eks describe-cluster --name innovatemart-eks --region us-east-1

# Verify nodes
kubectl get nodes -o wide

# Check all pods
kubectl get pods -A
```

### Application Verification
```bash
# Check application pods
kubectl get pods -n retail-store

# Check services
kubectl get svc -n retail-store

# Test application health
APP_URL=$(kubectl get svc ui -n retail-store -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$APP_URL/health
```

### Database Verification (BONUS)
```bash
# Check RDS instances
aws rds describe-db-instances

# Check DynamoDB table
aws dynamodb describe-table --table-name innovatemart-eks-carts

# Verify Kubernetes secrets
kubectl get secrets -n retail-store
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📧 Support

For issues, questions, or support:
- **GitHub Issues**: [Create an issue](https://github.com/ExcelIhenacho/innovatemart-bedrock/issues)
- **Email**: devops@innovatemart.com
- **Documentation**: See [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [AWS Retail Store Sample App](https://github.com/aws-containers/retail-store-sample-app)
- [Terraform AWS Modules](https://github.com/terraform-aws-modules)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

---

## 📊 Project Status

- ✅ Core Infrastructure - **Complete**
- ✅ Application Deployment - **Complete**
- ✅ CI/CD Pipeline - **Complete**
- ✅ Developer Access - **Complete**
- ✅ Managed Databases (BONUS) - **Complete**
- ✅ Advanced Networking (BONUS) - **Complete**
- ✅ Documentation - **Complete**

**Status**: Production Ready 🚀

---

**Project Bedrock** | Built with ❤️ by the InnovateMart DevOps Team from AltSchool Africa
**Last Updated**: October 24, 
