# ==============================================================================
# IAM Resources for Developer Access
# ==============================================================================

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# ==============================================================================
# Read-Only Developer IAM User
# ==============================================================================

resource "aws_iam_user" "developer" {
  name = var.developer_username
  path = "/"

  tags = {
    Project     = var.project_name
    Role        = "Developer"
    AccessLevel = "ReadOnly"
  }
}

# Create access key for the developer user
resource "aws_iam_access_key" "developer" {
  user = aws_iam_user.developer.name
}

# ==============================================================================
# IAM Policy for EKS Read-Only Access
# ==============================================================================

resource "aws_iam_policy" "eks_readonly" {
  name        = "${var.cluster_name}-readonly-policy"
  description = "Read-only access to EKS cluster resources"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EKSReadOnly"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:DescribeAddon",
          "eks:ListAddons",
          "eks:DescribeUpdate",
          "eks:ListUpdates"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchReadOnly"
        Effect = "Allow"
        Action = [
          "logs:Describe*",
          "logs:Get*",
          "logs:List*",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2ReadOnlyForEKS"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Project = var.project_name
  }
}

# Attach policy to developer user
resource "aws_iam_user_policy_attachment" "developer_eks_readonly" {
  user       = aws_iam_user.developer.name
  policy_arn = aws_iam_policy.eks_readonly.arn
}

# ==============================================================================
# Kubernetes RBAC Configuration via aws-auth ConfigMap
# ==============================================================================

# This maps the IAM user to a Kubernetes user with view-only permissions
resource "kubernetes_config_map_v1_data" "aws_auth" {
  force = true

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapUsers = yamlencode([
      {
        userarn  = aws_iam_user.developer.arn
        username = var.developer_username
        groups   = ["view-only-group"]
      }
    ])
  }

  depends_on = [
    module.eks
  ]
}

# ==============================================================================
# Kubernetes ClusterRole and ClusterRoleBinding for Read-Only Access
# ==============================================================================

resource "kubernetes_cluster_role" "readonly" {
  metadata {
    name = "view-only-role"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/log", "pods/status"]
    verbs      = ["get", "list"]
  }

  depends_on = [module.eks]
}

resource "kubernetes_cluster_role_binding" "readonly" {
  metadata {
    name = "view-only-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.readonly.metadata[0].name
  }

  subject {
    kind      = "Group"
    name      = "view-only-group"
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [module.eks]
}

