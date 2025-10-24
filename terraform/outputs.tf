# ==============================================================================
# EKS Cluster Outputs
# ==============================================================================

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_version" {
  description = "Kubernetes version"
  value       = module.eks.cluster_version
}

# ==============================================================================
# VPC Outputs
# ==============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

# ==============================================================================
# IAM Outputs for Developer Access
# ==============================================================================

output "developer_iam_user" {
  description = "IAM username for read-only developer"
  value       = aws_iam_user.developer.name
}

output "developer_iam_user_arn" {
  description = "IAM user ARN"
  value       = aws_iam_user.developer.arn
}

output "developer_access_key_id" {
  description = "Access Key ID for developer user (SENSITIVE)"
  value       = aws_iam_access_key.developer.id
  sensitive   = true
}

output "developer_secret_access_key" {
  description = "Secret Access Key for developer user (SENSITIVE)"
  value       = aws_iam_access_key.developer.secret
  sensitive   = true
}

# ==============================================================================
# Configuration Commands
# ==============================================================================

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "get_developer_credentials" {
  description = "Command to retrieve developer credentials"
  value       = "terraform output -raw developer_access_key_id && terraform output -raw developer_secret_access_key"
}

# ==============================================================================
# BONUS: Managed Database Outputs
# ==============================================================================

output "orders_db_endpoint" {
  description = "RDS PostgreSQL endpoint for Orders service"
  value       = try(aws_db_instance.orders_postgresql.endpoint, "Not deployed")
}

output "catalog_db_endpoint" {
  description = "RDS MySQL endpoint for Catalog service"
  value       = try(aws_db_instance.catalog_mysql.endpoint, "Not deployed")
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for Cart service"
  value       = try(aws_dynamodb_table.carts.name, "Not deployed")
}

output "orders_db_password" {
  description = "Password for Orders PostgreSQL database (SENSITIVE)"
  value       = try(random_password.orders_db_password.result, "Not deployed")
  sensitive   = true
}

output "catalog_db_password" {
  description = "Password for Catalog MySQL database (SENSITIVE)"
  value       = try(random_password.catalog_db_password.result, "Not deployed")
  sensitive   = true
}
