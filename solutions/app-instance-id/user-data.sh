#!/bin/bash
set -e
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)
echo "Instance ID: $INSTANCE_ID" > /home/ec2-user/index.html
sudo -u ec2-user nohup python3 -m http.server 8080 --directory /home/ec2-user &
echo "user-data script finished"
