#!/bin/bash
set -ex
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_DATA_FILE="$DIR/user-data.sh"

export AWS_REGION=${AWS_REGION:-"us-east-1"}

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

aws ec2 run-instances \
  --count 2 \
  --image-id "$AMI_ID" \
  --instance-type t4g.small \
  --subnet-id "$SUBNET_ID" \
  --security-group-ids "$SG_ID" \
  --associate-public-ip-address \
  --user-data "fileb://${USER_DATA_FILE}" \
  > .run-instances.json

INSTANCE_0_ID=$(jq -r .Instances[0].InstanceId .run-instances.json)
INSTANCE_1_ID=$(jq -r .Instances[1].InstanceId .run-instances.json)

aws ec2 wait instance-status-ok  --instance-ids "$INSTANCE_0_ID"
aws ec2 wait instance-status-ok  --instance-ids "$INSTANCE_1_ID"

INSTANCE_0_IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_0_ID" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
INSTANCE_1_IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_1_ID" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

curl http://${INSTANCE_0_IP}:8080
curl http://${INSTANCE_1_IP}:8080
