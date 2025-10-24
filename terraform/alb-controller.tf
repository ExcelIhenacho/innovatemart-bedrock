# ==============================================================================
# BONUS: AWS Load Balancer Controller
# ==============================================================================

# ==============================================================================
# IAM Role for AWS Load Balancer Controller
# ==============================================================================

module "aws_load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    Name = "${var.cluster_name}-aws-load-balancer-controller-role"
  }
}

# ==============================================================================
# Helm Release: AWS Load Balancer Controller
# ==============================================================================

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.1"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_load_balancer_controller_irsa_role.iam_role_arn
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  depends_on = [
    module.eks,
    module.aws_load_balancer_controller_irsa_role
  ]
}

# ==============================================================================
# ACM Certificate for HTTPS (Optional - requires domain)
# ==============================================================================

# Uncomment the following if you have a domain registered:

# variable "domain_name" {
#   type        = string
#   description = "Domain name for the application (e.g., innovatemart.example.com)"
#   default     = "innovatemart.example.com"
# }
#
# data "aws_route53_zone" "main" {
#   name         = "example.com"  # Your root domain
#   private_zone = false
# }
#
# resource "aws_acm_certificate" "main" {
#   domain_name       = var.domain_name
#   validation_method = "DNS"
#
#   subject_alternative_names = [
#     "*.${var.domain_name}"
#   ]
#
#   lifecycle {
#     create_before_destroy = true
#   }
#
#   tags = {
#     Name = "${var.cluster_name}-certificate"
#   }
# }
#
# resource "aws_route53_record" "cert_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }
#
#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = data.aws_route53_zone.main.zone_id
# }
#
# resource "aws_acm_certificate_validation" "main" {
#   certificate_arn         = aws_acm_certificate.main.arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
# }
#
# output "certificate_arn" {
#   description = "ARN of the ACM certificate"
#   value       = aws_acm_certificate.main.arn
# }

