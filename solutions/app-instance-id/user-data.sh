#!/bin/bash
# Exit on errors
set -e

# Install Python (Amazon Linux 2 usually has it, but ensure it's there)
yum install -y python3

# Get a session token for IMDSv2 (valid for 6 hours)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# Fetch the instance ID using the token
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)

# Create a simple HTML page with the instance ID
cat <<EOF > /home/ec2-user/index.html
<html>
<head><title>EC2 Instance</title></head>
<body>
<h1>Hello from EC2!</h1>
<p>Instance ID: <b>$INSTANCE_ID</b></p>
</body>
</html>
EOF

# Change to ec2-user's home directory
cd /home/ec2-user

# Serve the page using Python's SimpleHTTPServer (on port 80)
# Run in background so the user data script finishes
nohup python3 -m http.server 80 --directory /home/ec2-user &
