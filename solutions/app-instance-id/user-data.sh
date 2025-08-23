#!/bin/bash
set -ex
yum install -y python3
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)
cat <<EOF > /home/ec2-user/index.html
<html>
<head><title>EC2 Instance $INSTANCE_ID</title></head>
<body>
<h1>Hello from EC2!</h1>
<p>Instance ID: <b>$INSTANCE_ID</b></p>
</body>
</html>
EOF
nohup python3 -m http.server 80 --directory /home/ec2-user &
echo "user-data script finished"
