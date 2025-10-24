# ==============================================================================
# EKS Add-ons
# ==============================================================================

# VPC CNI - Networking plugin for pod networking
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "vpc-cni"
  addon_version               = "v1.18.1-eksbuild.3"
  resolve_conflicts_on_update = "PRESERVE"

  tags = {
    Name = "${var.cluster_name}-vpc-cni"
  }
}

# CoreDNS - DNS server for service discovery
resource "aws_eks_addon" "coredns" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "coredns"
  addon_version               = "v1.11.1-eksbuild.9"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [
    aws_eks_addon.vpc_cni
  ]

  tags = {
    Name = "${var.cluster_name}-coredns"
  }
}

# Kube-proxy - Network proxy that runs on each node
resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "kube-proxy"
  addon_version               = "v1.30.0-eksbuild.3"
  resolve_conflicts_on_update = "PRESERVE"

  tags = {
    Name = "${var.cluster_name}-kube-proxy"
  }
}

# Pod Identity Agent - Allows pods to assume IAM roles
resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "eks-pod-identity-agent"
  addon_version               = "v1.3.0-eksbuild.1"
  resolve_conflicts_on_update = "PRESERVE"

  tags = {
    Name = "${var.cluster_name}-pod-identity-agent"
  }
}

# ==============================================================================
# EBS CSI Driver for Persistent Volumes
# ==============================================================================

# IAM role for EBS CSI driver using IRSA
module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name             = "${var.cluster_name}-ebs-csi-driver"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = {
    Name = "${var.cluster_name}-ebs-csi-driver-role"
  }
}

# EBS CSI Driver addon
resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = "v1.32.0-eksbuild.1"
  resolve_conflicts_on_update = "PRESERVE"
  service_account_role_arn    = module.ebs_csi_irsa_role.iam_role_arn

  depends_on = [
    module.ebs_csi_irsa_role
  ]

  tags = {
    Name = "${var.cluster_name}-ebs-csi-driver"
  }
}
