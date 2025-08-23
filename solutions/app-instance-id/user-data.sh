#!/bin/bash
set -e

yum install -y python3 iptables

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

cd /home/ec2-user
nohup python3 -m http.server 8080 --directory /home/ec2-user &
iptables -t nat -I PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
