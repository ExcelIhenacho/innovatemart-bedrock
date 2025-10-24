# 🚀 Quick Start Guide - InnovateMart Project Bedrock

This guide will help you deploy the complete infrastructure in under 30 minutes.

---

## ⚡ Fast Track Deployment

### Prerequisites Check
```bash
# Verify all tools are installed
aws --version        # Should be 2.x+
terraform version    # Should be >= 1.0
kubectl version      # Should be >= 1.30
git --version        # Any recent version
```

---

## 📦 Step 1: Setup (5 minutes)

### 1.1 Clone and Navigate
```bash
git clone https://github.com/ExcelIhenacho/innovatemart-bedrock.git
cd innovatemart-bedrock
```

### 1.2 Create S3 Bucket for Terraform State
```bash
# Choose a UNIQUE bucket name
BUCKET_NAME="innovatemart-tfstate-$(date +%s)"

# Create bucket
aws s3 mb s3://${BUCKET_NAME} --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket ${BUCKET_NAME} \
  --versioning-configuration Status=Enabled

# Save bucket name for later
echo ${BUCKET_NAME}
```

### 1.3 Update Backend Configuration
```bash
# Edit terraform/backend.tf and replace bucket name
# Replace line 3: bucket = "YOUR_BUCKET_NAME_HERE"

# On Linux/Mac:
sed -i "s/innovatemart-tfstate-excel/${BUCKET_NAME}/" terraform/backend.tf

# On Windows (PowerShell):
# (Get-Content terraform\backend.tf) -replace 'innovatemart-tfstate-excel', $BUCKET_NAME | Set-Content terraform\backend.tf
```

---

## 🏗️ Step 2: Deploy Infrastructure (15-20 minutes)

### 2.1 Initialize and Deploy
```bash
cd terraform

# Initialize Terraform
terraform init

# Review the plan (optional but recommended)
terraform plan

# Deploy everything
terraform apply
# Type 'yes' when prompted
```

**☕ Coffee Break**: This takes ~15-20 minutes. The EKS cluster creation is the longest part.

### 2.2 Save Important Outputs
```bash
# After apply completes, save these:
terraform output cluster_name
terraform output region
terraform output developer_iam_user

# Save credentials securely
terraform output -raw developer_access_key_id > ../dev-access-key.txt
terraform output -raw developer_secret_access_key >> ../dev-access-key.txt
```

---

## 🚢 Step 3: Deploy Application (5 minutes)

### 3.1 Configure kubectl
```bash
cd .. 

aws eks update-kubeconfig --region us-east-1 --name innovatemart-eks

# Verify cluster access
kubectl get nodes
```

### 3.2 Deploy Application

**Option A: Basic Deployment (In-Cluster Databases)**
```bash
kubectl apply -f k8s/retail-store-app.yaml

# Wait for pods to be ready (3-5 minutes)
kubectl get pods -n retail-store --watch
```

**Option B: With Managed AWS Databases (BONUS)**
```bash
kubectl apply -f k8s/retail-store-managed-db.yaml

# Wait for pods (may take 5-7 minutes as databases initialize)
kubectl get pods -n retail-store --watch
```

**Option C: With Managed Databases + Ingress/ALB (FULL BONUS)**
```bash
kubectl apply -f k8s/retail-store-managed-db.yaml
kubectl apply -f k8s/ingress-alb.yaml

# Wait for pods and ALB provisioning
kubectl get pods -n retail-store --watch
```

---

## 🌐 Step 4: Access Application (2 minutes)

### Get Application URL
```bash
# Wait for LoadBalancer to be ready
kubectl get svc ui -n retail-store --watch
# Press Ctrl+C when EXTERNAL-IP shows a hostname

# Get the URL
echo "Application URL: http://$(kubectl get svc ui -n retail-store -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
```

### Open in Browser
```bash
# Copy the URL and open in your browser
# Example: http://a1b2c3d4...elb.amazonaws.com

# Or use curl to test
curl -I http://$(kubectl get svc ui -n retail-store -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

---

## ✅ Step 5: Verify Everything Works

### 5.1 Check Infrastructure
```bash
# All nodes should be Ready
kubectl get nodes

# All pods should be Running
kubectl get pods -n retail-store

# Services should have endpoints
kubectl get svc -n retail-store

# Check RDS databases (if using managed option)
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]'

# Check DynamoDB table (if using managed option)
aws dynamodb describe-table --table-name innovatemart-eks-carts
```

### 5.2 Test Developer Access
```bash
# Configure developer profile
aws configure --profile innovatemart-dev
# Enter credentials from dev-access-key.txt

# Test read-only access
aws eks update-kubeconfig --region us-east-1 --name innovatemart-eks --profile innovatemart-dev

# Should work
kubectl get pods -n retail-store

# Should fail with Forbidden
kubectl delete pod <any-pod-name> -n retail-store
```

---

## 🔄 Step 6: Setup CI/CD (Optional, 5 minutes)

### 6.1 Configure GitHub Secrets
1. Go to GitHub Repository
2. Settings → Secrets and variables → Actions
3. Add New Repository Secret:
   - Name: `AWS_ACCESS_KEY_ID`
   - Value: Your AWS access key
4. Add another secret:
   - Name: `AWS_SECRET_ACCESS_KEY`
   - Value: Your AWS secret key

### 6.2 Test Pipeline
```bash
# Create a test branch
git checkout -b test/pipeline

# Make a small change
echo "# Test change" >> terraform/variables.tf

# Commit and push
git add .
git commit -m "test: trigger CI/CD pipeline"
git push origin test/pipeline