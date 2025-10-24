# InnovateMart Project Bedrock - Deployment Guide

**Project**: EKS Microservices Deployment  
**Author**: [Your Name]  
**Date**: October 2025  
**Repository**: https://github.com/ExcelIhenacho/innovatemart-bedrock

---

## 📋 Prerequisites

### Required Tools
- **AWS CLI v2+**: `aws --version`
- **Terraform v1.0+**: `terraform version`
- **kubectl v1.30+**: `kubectl version --client`
- **Git**: `git --version`

### AWS Account Setup
```bash
# Configure AWS credentials
aws configure
# Enter: Access Key, Secret Key, Region (us-east-1), Output (json)

# Verify access
aws sts get-caller-identity
```

---

## 🚀 Quick Deployment (30 minutes)

### Step 1: Create S3 Bucket (2 min)
```bash
# Create unique bucket name
BUCKET_NAME="innovatemart-tfstate-$(date +%s)"
echo "Bucket: $BUCKET_NAME"

# Create bucket
aws s3 mb s3://$BUCKET_NAME --region us-east-1
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled
```

### Step 2: Update Backend Configuration (1 min)
```bash
# Update terraform/backend.tf
# Change line 3: bucket = "innovatemart-tfstate-excel"
# To: bucket = "$BUCKET_NAME"

# Windows PowerShell:
(Get-Content terraform\backend.tf) -replace 'innovatemart-tfstate-excel', $BUCKET_NAME | Set-Content terraform\backend.tf

# Linux/Mac:
sed -i "s/innovatemart-tfstate-excel/$BUCKET_NAME/" terraform/backend.tf
```

### Step 3: Deploy Infrastructure (15-20 min)
```bash
cd terraform

# Initialize and deploy
terraform init
terraform plan    # Review changes
terraform apply   # Type 'yes'

# Save outputs
terraform output cluster_name
terraform output developer_iam_user
```

### Step 4: Configure kubectl (1 min)
```bash
cd ..
aws eks update-kubeconfig --region us-east-1 --name innovatemart-eks
kubectl get nodes  # Verify connection
```

### Step 5: Deploy Application (5 min)
```bash
# Deploy retail store app
kubectl apply -f k8s/retail-store-app.yaml

# Monitor deployment
kubectl get pods -n retail-store --watch
# Press Ctrl+C when all pods are "Running"
```

### Step 6: Access Application (1 min)
```bash
# Get LoadBalancer URL
kubectl get svc ui -n retail-store

# Get exact URL
echo "App URL: http://$(kubectl get svc ui -n retail-store -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
```

---

## 🏗️ Architecture Overview

### Infrastructure Components
- **VPC**: 10.0.0.0/16 with 2 public + 2 private subnets
- **EKS Cluster**: Kubernetes 1.31 with managed node groups
- **Node Group**: 2-4 t3.medium instances (auto-scaling)
- **EKS Add-ons**: VPC CNI, CoreDNS, kube-proxy, EBS CSI, Pod Identity

### Application Services
| Service | Replicas | Database | Purpose |
|---------|----------|----------|---------|
| UI | 2 | - | Frontend web interface |
| Catalog | 2 | MySQL 5.7 | Product catalog |
| Cart | 2 | Redis 7 | Shopping cart |
| Orders | 2 | PostgreSQL 16 | Order processing |
| Checkout | 2 | - | Checkout flow |
| Assets | 2 | - | Static assets |

---

## 👥 Developer Access Setup

### Create Developer User
```bash
cd terraform

# Get developer credentials
terraform output -raw developer_access_key_id
terraform output -raw developer_secret_access_key
```

### Developer Configuration
```bash
# Configure AWS CLI
aws configure --profile innovatemart-dev
# Enter provided credentials, region: us-east-1

# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name innovatemart-eks --profile innovatemart-dev

# Test access
kubectl get pods -n retail-store  # Should work
kubectl delete pod test -n retail-store  # Should fail with "Forbidden"
```

### Developer Permissions
- ✅ **Allowed**: `get`, `list`, `watch` on all resources
- ✅ **Allowed**: View logs, describe pods, check status
- ❌ **Denied**: Create, update, delete resources

---

## 🔄 CI/CD Pipeline Setup

### GitHub Actions Configuration
1. **Repository Settings** → **Secrets and variables** → **Actions**
2. Add secrets:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

### Pipeline Workflow
- **Pull Request** → Runs `terraform plan` and comments results
- **Merge to main** → Runs `terraform apply` automatically
- **Application changes** → Deploys to EKS cluster

### Test Pipeline
```bash
# Create test branch
git checkout -b test/pipeline
echo "# Test change" >> terraform/variables.tf
git add . && git commit -m "test: trigger pipeline"
git push origin test/pipeline
# Create PR on GitHub and watch pipeline run
```

---

## 🎯 Bonus Features (Optional)

### Managed Databases
```bash
# Deploy with AWS managed databases
kubectl apply -f k8s/retail-store-managed-db.yaml

# Includes:
# - RDS PostgreSQL for Orders
# - RDS MySQL for Catalog  
# - DynamoDB for Cart
```

### Advanced Networking
```bash
# Deploy with ALB Ingress
kubectl apply -f k8s/ingress-alb.yaml

# Features:
# - Application Load Balancer
# - Health checks
# - SSL/TLS support (with certificate ARN)
```

---

## ✅ Verification & Testing

### Infrastructure Check
```bash
# Verify EKS cluster
aws eks describe-cluster --name innovatemart-eks --region us-east-1

# Check nodes
kubectl get nodes -o wide

# Check all pods
kubectl get pods -n retail-store
```

### Application Health
```bash
# Check services
kubectl get svc -n retail-store

# Test application
APP_URL=$(kubectl get svc ui -n retail-store -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl -I http://$APP_URL/health
```

### Developer Access Test
```bash
# Test read operations
kubectl get pods -n retail-store
kubectl logs <pod-name> -n retail-store

# Test write operations (should fail)
kubectl delete pod <pod-name> -n retail-store
```

---

## 🆘 Troubleshooting

### Common Issues

**Terraform state bucket not found**
```bash
# Solution: Create S3 bucket first
aws s3 mb s3://your-bucket-name --region us-east-1
```

**kubectl can't connect to cluster**
```bash
# Solution: Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name innovatemart-eks --force
```

**Pods stuck in Pending**
```bash
# Check node capacity
kubectl describe nodes
kubectl describe pod <pod-name> -n retail-store
```

**LoadBalancer no external IP**
```bash
# Wait 2-3 minutes
kubectl get svc ui -n retail-store --watch
# Check AWS Console → EC2 → Load Balancers
```

### Useful Commands
```bash
# View all resources
kubectl get all -n retail-store

# Check pod logs
kubectl logs <pod-name> -n retail-store

# Restart deployment
kubectl rollout restart deployment <name> -n retail-store
```

---

## 🗑️ Cleanup

### Full Cleanup
```bash
# Delete application
kubectl delete -f k8s/retail-store-app.yaml

# Wait for LoadBalancers to be deleted
sleep 120

# Destroy infrastructure
cd terraform
terraform destroy
# Type 'yes' when prompted
```

### Cost Information
- **Hourly**: ~$0.30
- **Daily**: ~$7.00  
- **Monthly**: ~$220.00

**💡 Tip**: Destroy resources when not using to save costs!

---

## 📊 Project Status

- ✅ **Core Infrastructure**: VPC, EKS, IAM roles
- ✅ **Application Deployment**: All microservices running
- ✅ **Developer Access**: Read-only IAM user configured
- ✅ **CI/CD Pipeline**: GitHub Actions automated
- ✅ **Documentation**: Complete deployment guide
- ✅ **Bonus Features**: Managed databases, ALB Ingress

**Status**: Production Ready 🚀

---

## 📞 Support

- **Documentation**: README.md, QUICKSTART.md
- **Issues**: Check Terraform/kubectl logs
- **AWS Docs**: https://docs.aws.amazon.com/
- **Kubernetes Docs**: https://kubernetes.io/docs/

---

**Document Version**: 1.0  
**Last Updated**: October 2025  
**Maintained By**: InnovateMart DevOps Team at Altschool Africa

