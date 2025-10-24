# ==============================================================================
# BONUS: Amazon DynamoDB for Cart Service
# ==============================================================================

resource "aws_dynamodb_table" "carts" {
  name           = "${var.cluster_name}-carts"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "customerId"
    type = "S"
  }

  global_secondary_index {
    name            = "customerId-index"
    hash_key        = "customerId"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "${var.cluster_name}-carts-table"
    Service     = "carts"
    ManagedBy   = "Terraform"
  }
}

# ==============================================================================
# IAM Role for Cart Service to Access DynamoDB
# ==============================================================================

module "carts_dynamodb_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-carts-dynamodb"

  role_policy_arns = {
    policy = aws_iam_policy.carts_dynamodb.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["retail-store:carts"]
    }
  }

  tags = {
    Name = "${var.cluster_name}-carts-dynamodb-role"
  }
}

resource "aws_iam_policy" "carts_dynamodb" {
  name        = "${var.cluster_name}-carts-dynamodb-policy"
  description = "IAM policy for carts service to access DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = [
          aws_dynamodb_table.carts.arn,
          "${aws_dynamodb_table.carts.arn}/index/*"
        ]
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-carts-dynamodb-policy"
  }
}

# ==============================================================================
# Kubernetes Service Account for Cart Service
# ==============================================================================

resource "kubernetes_service_account" "carts" {
  metadata {
    name      = "carts"
    namespace = "retail-store"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.carts_dynamodb_irsa_role.iam_role_arn
    }
  }

  depends_on = [kubernetes_namespace.retail_store]
}

# ==============================================================================
# Kubernetes ConfigMap for DynamoDB Configuration
# ==============================================================================

resource "kubernetes_config_map" "carts_dynamodb" {
  metadata {
    name      = "carts-dynamodb-config"
    namespace = "retail-store"
  }

  data = {
    DYNAMODB_TABLE_NAME = aws_dynamodb_table.carts.name
    AWS_REGION          = var.region
    DYNAMODB_ENDPOINT   = "https://dynamodb.${var.region}.amazonaws.com"
  }

  depends_on = [kubernetes_namespace.retail_store]
}

