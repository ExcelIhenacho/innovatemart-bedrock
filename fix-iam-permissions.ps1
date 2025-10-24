# Fix IAM Permissions for EKS Access - PowerShell Version
# Run this script to add the required EKS permissions to your AWS user

Write-Host "🔧 Fixing IAM Permissions for EKS Access..." -ForegroundColor Green

# Get current user ARN
$UserArn = (aws sts get-caller-identity --query 'Arn' --output text)
Write-Host "Current user: $UserArn" -ForegroundColor Yellow

# Create IAM policy for EKS access
$PolicyJson = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeCluster",
                "eks:ListClusters",
                "eks:DescribeNodegroup",
                "eks:ListNodegroups",
                "eks:DescribeAddon",
                "eks:ListAddons",
                "eks:DescribeUpdate",
                "eks:ListUpdates",
                "eks:AccessKubernetesApi",
                "eks:ListClusters"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "arn:aws:iam::*:role/*EKS*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeInstances",
                "ec2:DescribeImages",
                "ec2:DescribeKeyPairs",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeAccountAttributes"
            ],
            "Resource": "*"
        }
    ]
}
"@

# Save policy to file
$PolicyJson | Out-File -FilePath "eks-policy.json" -Encoding UTF8
Write-Host "📝 Created EKS policy file: eks-policy.json" -ForegroundColor Green

# Create the policy
Write-Host "Creating IAM policy..." -ForegroundColor Yellow
aws iam create-policy --policy-name EKSFullAccess --policy-document file://eks-policy.json --description "Full access to EKS clusters and related resources"

# Get policy ARN
$PolicyArn = (aws iam list-policies --query 'Policies[?PolicyName==`EKSFullAccess`].Arn' --output text)
Write-Host "Policy ARN: $PolicyArn" -ForegroundColor Yellow

# Extract username from ARN
$Username = $UserArn.Split('/')[1]
Write-Host "Username: $Username" -ForegroundColor Yellow

# Attach policy to user
Write-Host "Attaching policy to user..." -ForegroundColor Yellow
aws iam attach-user-policy --user-name $Username --policy-arn $PolicyArn

Write-Host "✅ IAM permissions updated successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "You can now run:" -ForegroundColor Cyan
Write-Host "  cd terraform" -ForegroundColor White
Write-Host "  terraform init" -ForegroundColor White
Write-Host "  terraform apply" -ForegroundColor White
Write-Host ""
Write-Host "If you still get permission errors, wait 2-3 minutes for AWS to propagate the changes." -ForegroundColor Yellow
