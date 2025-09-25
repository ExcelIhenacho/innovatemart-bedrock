variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "innovatemart-bedrock"
}

variable "cluster_name" {
  type    = string
  default = "innovatemart-eks"
}

variable "cluster_version" {
  type    = string
  default = "1.32"
}
