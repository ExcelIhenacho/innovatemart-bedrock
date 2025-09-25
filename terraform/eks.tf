module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0" # stable with AWS provider 5.x

  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    ng_default = {
      desired_size   = 2
      min_size       = 2
      max_size       = 3
      instance_types = ["t3.medium"]
      disk_size      = 20
    }
  }

  tags = {
    Project = var.project_name
  }
}
