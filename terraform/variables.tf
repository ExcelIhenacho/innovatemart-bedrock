variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for resources"
}

variable "project_name" {
  type        = string
  default     = "innovatemart-bedrock"
  description = "Project name for tagging"
}

variable "cluster_name" {
  type        = string
  default     = "innovatemart-eks"
  description = "EKS cluster name"
}

variable "cluster_version" {
  type        = string
  default     = "1.31"
  description = "Kubernetes version for EKS cluster"
}

variable "developer_username" {
  type        = string
  default     = "innovatemart-dev-readonly"
  description = "IAM username for read-only developer access"
}

variable "node_desired_size" {
  type        = number
  default     = 2
  description = "Desired number of worker nodes"
}

variable "node_min_size" {
  type        = number
  default     = 2
  description = "Minimum number of worker nodes"
}

variable "node_max_size" {
  type        = number
  default     = 4
  description = "Maximum number of worker nodes"
}

variable "node_instance_types" {
  type        = list(string)
  default     = ["t3.medium"]
  description = "EC2 instance types for EKS worker nodes"
}
