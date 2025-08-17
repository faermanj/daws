#!/bin/bash
set -ex
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_DATA_FILE="$DIR/user-data.sh"

export AWS_REGION=${AWS_REGION:-"us-east-1" }

# Get latest Amazon Linux 2023 ARM64 AMI
AMI_ID=$(aws ssm get-parameter \
  --name "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-arm64" \
  --query "Parameter.Value" --output text)

# Get default VPC and first subnet
VPC_ID=$(aws ec2 describe-vpcs \
  --filters Name=isDefault,Values=true \
  --query "Vpcs[0].VpcId" --output text)

SUBNET_ID=$(aws ec2 describe-subnets \
  --filters Name=vpc-id,Values="$VPC_ID" \
  --query "Subnets[0].SubnetId" --output text)

GROUP_NAME="simple-instance-id-sg"
SG_ID=$(aws ec2 describe-security-groups \
    --filters Name=group-name,Values="$GROUP_NAME" Name=vpc-id,Values="$VPC_ID" \
    --query "SecurityGroups[0].GroupId" --output text)

if [ "$SG_ID" == "None" ] || [ -z "$SG_ID" ]; then
    SG_ID=$(aws ec2 create-security-group \
        --group-name "$GROUP_NAME" --description "HTTP only" \
        --vpc-id "$VPC_ID" --query "GroupId" --output text)
    aws ec2 authorize-security-group-ingress --group-id "$SG_ID" \
     --protocol tcp --port 80 --cidr 0.0.0.0/0
fi



# Launch the instance
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type t4g.small \
  --subnet-id "$SUBNET_ID" \
  --security-group-ids "$SG_ID" \
  --associate-public-ip-address \
  --user-data "fileb://${USER_DATA_FILE}" \
  --query "Instances[0].InstanceId" --output text)

# Wait for it and get the public IP
aws ec2 wait instance-status-ok  --instance-ids "$INSTANCE_ID"
PUBLIC_IP=$(aws ec2 describe-instances  \
  --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

echo "Instance: $INSTANCE_ID"
echo "URL: http://$PUBLIC_IP/"
