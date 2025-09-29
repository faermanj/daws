#!/bin/bash
echo "Running user-data.sh script..."
# Install Java if not present (prefer Amazon Corretto headless)
if ! command -v java >/dev/null 2>&1; then
  sudo rpm --import https://rpm.corretto.aws/corretto.key
  sudo curl -L https://rpm.corretto.aws/corretto.repo -o /etc/yum.repos.d/corretto.repo
  sudo yum install -y java-25-amazon-corretto-headless
fi
java -version
# Install Maven if not present
if ! command -v mvn >/dev/null 2>&1; then
    sudo yum install -y maven
fi
mvn -version
# Install Git if not present
if ! command -v git >/dev/null 2>&1; then
    sudo yum install -y git
fi
git --version
# Clone the repository if not already present
REPO_DIR="/home/ec2-user/daws"
if [ ! -d "$REPO_DIR" ]; then
    git clone https://github.com/faermanj/daws.git "$REPO_DIR"
fi
echo "Starting crud-quarkus/crud-api
cd "$REPO_DIR/solutions/crud-quarkus/dist"
cat <<EOL > .envrc
export QUARKUS_DATASOURCE_JDBC_URL='${QUARKUS_DATASOURCE_JDBC_URL}'
export QUARKUS_DATASOURCE_USERNAME='${QUARKUS_DATASOURCE_USERNAME}'
export QUARKUS_DATASOURCE_PASSWORD='${QUARKUS_DATASOURCE_PASSWORD}'
EOL
sudo -u ec2-user nohup source .envrc && java -jar quarkus-run.jar &
echo "Done user-data.sh script."


