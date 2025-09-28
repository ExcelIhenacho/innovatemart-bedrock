# 🚀 InnovateMart – Project Bedrock

Deploy the **Retail Store Sample App** to an **Amazon EKS** cluster using **Infrastructure as Code (Terraform)** and a fully automated **CI/CD pipeline**.

---

## 📑 Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Infrastructure Setup](#infrastructure-setup)
- [Application Deployment](#application-deployment)
- [Developer Read-Only Access](#developer-read-only-access)
- [CI/CD Pipeline](#cicd-pipeline)
- [Bonus Objectives](#bonus-objectives)
- [Repository Structure](#repository-structure)
- [Useful Commands](#useful-commands)
- [License](#license)

---

## 📝 Overview
InnovateMart’s **Project Bedrock** deploys a microservices-based **Retail Store Sample App** to a production-ready **Amazon Elastic Kubernetes Service (EKS)** cluster.

**Key Goals**
- ✅ Automate AWS resource provisioning with **Terraform**  
- ✅ Deploy application workloads using **Kubernetes manifests**  
- ✅ Provide secure, read-only developer access  
- ✅ Implement **CI/CD** using GitHub Actions

---

## 🏗️ Architecture
- **AWS VPC** with public and private subnets  
- **Amazon EKS Cluster** with managed node groups  
- **Kubernetes Deployments** for microservices: `UI`, `orders`, `catalog`, `carts`, etc.  
- Optional managed persistence: **RDS (PostgreSQL/MySQL)**, **DynamoDB**  
- Optional networking stack: **Ingress + ALB + Route53** for HTTPS and custom domains

---

## 🔑 Prerequisites
1. **AWS Account** with admin access
2. Installed tools:
   - [Terraform v1.10.0+](https://developer.hashicorp.com/terraform/downloads)  
   - [kubectl](https://kubernetes.io/docs/tasks/tools/)  
   - [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
3. Configure AWS CLI:
   ```bash
   aws configure
   # Enter Access Key, Secret Key, Region (us-east-1), Output format (json)
   ```

---

## ⚙️ Infrastructure Setup
### 1️⃣ Clone the Repository
```bash
git clone https://github.com/<your-username>/innovatemart-bedrock.git
cd innovatemart-bedrock/terraform
```

### 2️⃣ Initialize & Apply Terraform
```bash
terraform init
terraform plan
terraform apply -auto-approve
```

**Provisioned Resources**
- VPC & subnets  
- EKS cluster & node groups  
- IAM roles & policies  
- Core add-ons: CoreDNS, VPC CNI, EBS CSI

---

## 🚢 Application Deployment
1. Update kubeconfig:
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name innovatemart-eks
   ```
2. Deploy the sample app:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/aws-containers/retail-store-sample-app/main/deploy/kubernetes/complete-demo.yaml
   ```
3. Verify:
   ```bash
   kubectl get pods -A
   ```

---

## 👥 Developer Read-Only Access
1. **Create IAM User**: `innovatemart-dev-readonly`  
2. **Attach Inline Policy**:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       { "Effect": "Allow", "Action": ["eks:DescribeCluster"], "Resource": "*" },
       { "Effect": "Allow", "Action": ["logs:Describe*", "logs:Get*", "logs:List*"], "Resource": "*" }
     ]
   }
   ```
3. **Add IAM User to EKS Auth**:
   ```yaml
   mapUsers: |
     - userarn: arn:aws:iam::<account_id>:user/innovatemart-dev-readonly
       username: dev-readonly
       groups:
         - view
   ```
4. Provide the developer with:
   - `kubeconfig` context  
   - AWS access key/secret key  
   - Instructions for `kubectl` read-only commands

---

## 🔄 CI/CD Pipeline
GitHub Actions workflow: **`.github/workflows/terraform.yml`**
```yaml
name: Terraform Deploy
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.10.0
      - name: Terraform Init
        run: terraform -chdir=terraform init
      - name: Terraform Plan
        if: github.event_name == 'pull_request'
        run: terraform -chdir=terraform plan
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: terraform -chdir=terraform apply -auto-approve
```

**Required GitHub Secrets**
- `AWS_ACCESS_KEY_ID`  
- `AWS_SECRET_ACCESS_KEY`  
- `AWS_REGION` (e.g., `us-east-1`)

---

## 🎯 Bonus Objectives
- **Managed Databases**: RDS PostgreSQL/MySQL, DynamoDB  
- **Networking & Security Enhancements**:
  - AWS Load Balancer Controller  
  - Kubernetes Ingress + Route53 + ACM for HTTPS & custom domain

---

## 📂 Repository Structure
```
innovatemart-bedrock/
│
├── terraform/
│   ├── addons.tf
│   ├── backend.tf
│   ├── eks.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── versions.tf
│   └── vpc.tf
├── .github/
│   └── workflows/terraform.yml
└── README.md
```

---

## 🛠️ Useful Commands
- **Check Nodes:** `kubectl get nodes`  
- **View Logs:** `kubectl logs <pod-name>`  
- **Scale Deployment:** `kubectl scale deployment <name> --replicas=3`

---

## 📜 License
This project is licensed under the **MIT License**.

---
