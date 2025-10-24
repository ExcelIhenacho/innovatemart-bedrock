#!/bin/bash

# Fix IAM Permissions for EKS Access
# Run this script to add the required EKS permissions to your AWS user

echo "🔧 Fixing IAM Permissions for EKS Access..."

# Get current user ARN
USER_ARN=$(aws sts get-caller-identity --query 'Arn' --output text)
echo "Current user: $USER_ARN"

# Create IAM policy for EKS access
cat > eks-policy.json << EOF
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
EOF

echo "📝 Created EKS policy file: eks-policy.json"

# Create the policy
echo "Creating IAM policy..."
aws iam create-policy \
    --policy-name EKSFullAccess \
    --policy-document file://eks-policy.json \
    --description "Full access to EKS clusters and related resources"

# Get policy ARN
POLICY_ARN=$(aws iam list-policies --query 'Policies[?PolicyName==`EKSFullAccess`].Arn' --output text)
echo "Policy ARN: $POLICY_ARN"

# Extract username from ARN
USERNAME=$(echo $USER_ARN | cut -d'/' -f2)
echo "Username: $USERNAME"

# Attach policy to user
echo "Attaching policy to user..."
aws iam attach-user-policy \
    --user-name $USERNAME \
    --policy-arn $POLICY_ARN

echo "✅ IAM permissions updated successfully!"
echo ""
echo "You can now run:"
echo "  cd terraform"
echo "  terraform init"
echo "  terraform apply"
echo ""
echo "If you still get permission errors, wait 2-3 minutes for AWS to propagate the changes."
