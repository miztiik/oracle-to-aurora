#!/bin/bash
set -ex
set -o pipefail

# version: 04Aug2020

##################################################
#############     SET GLOBALS     ################
##################################################

# Troubleshoot here
# /var/lib/cloud/instance/scripts/part-001:
# /var/log/user-data.log

REPO_NAME="dms-mongodb-to-documentdb"

GIT_REPO_URL="https://github.com/miztiik/$REPO_NAME.git"

APP_DIR="/var/$REPO_NAME"

# Send logs to console
# exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1



instruction()
{
  echo "usage: ./build.sh package <stage> <region>"
  echo ""
  echo "/build.sh deploy <stage> <region> <pkg_dir>"
  echo ""
  echo "/build.sh test-<test_type> <stage>"
}

assume_role() {
  if [ -n "$DEPLOYER_ROLE_ARN" ]; then
    echo "Assuming role $DEPLOYER_ROLE_ARN ..."
    CREDS=$(aws sts assume-role --role-arn $DEPLOYER_ROLE_ARN \
        --role-session-name my-sls-session --out json)
    echo $CREDS > temp_creds.json
    export AWS_ACCESS_KEY_ID=$(node -p "require('./temp_creds.json').Credentials.AccessKeyId")
    export AWS_SECRET_ACCESS_KEY=$(node -p "require('./temp_creds.json').Credentials.SecretAccessKey")
    export AWS_SESSION_TOKEN=$(node -p "require('./temp_creds.json').Credentials.SessionToken")
    aws sts get-caller-identity
  fi
}

unassume_role() {
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN
}

function install_xray(){
    # Install AWS XRay Daemon for telemetry
    curl https://s3.dualstack.us-east-2.amazonaws.com/aws-xray-assets.us-east-2/xray-daemon/aws-xray-daemon-3.x.rpm -o /home/ec2-user/xray.rpm
    yum install -y /home/ec2-user/xray.rpm
}

function install_nginx(){
    echo 'Begin NGINX Installation'
    sudo amazon-linux-extras install -y nginx1.12
    sudo systemctl start nginx
}

function clone_git_repo(){
    install_libs
    # mkdir -p /var/
    cd /var
    git clone $GIT_REPO_URL

}

function add_env_vars(){
    EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
    AWS_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed 's/[a-z]$//'`"
    export AWS_REGION
    sudo touch /var/log/miztiik-load-generator-unthrottled.log
    sudo touch /var/log/miztiik-load-generator-throttled.log
    sudo chmod 775 /var/log/miztiik-load-generator-*
    sudo chown root:ssm-user /var/log/miztiik-load-generator-*
}

function install_libs(){
    # Prepare the server for python3
    yum -y install python-pip python3 git
    yum install -y jq
    pip3 install boto3 pymongo
}

function install_nodejs(){
    # https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/setting-up-node-on-ec2-instance.html
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
    . ~/.nvm/nvm.sh
    nvm install node
    node -e "console.log('Running Node.js ' + process.version)"
}

function install_mongodb(){
# db.createUser({ user: 'mongoDbAdmin', pwd: 'Som3thingSh0uldBe1nVault', roles: [{ role: 'read', db:'local'},{ role: 'userAdminAnyDatabase', db:'admin'},{ role: 'dbAdminAnyDatabase', db:'admin'},{ role: 'readWriteAnyDatabase', db:'admin'}]})

cat > '/etc/yum.repos.d/mongodb-org-4.4.repo' << "EOF"
[mongodb-org-4.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/4.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc
EOF
    sudo yum install -y mongodb-org

    sudo systemctl daemon-reload
    sudo systemctl start mongod
    sudo systemctl enable mongod
cat > 'mongo_create_admin_user.js' << "EOF"
use admin
db.createUser({ user: "root", pwd: "Som3thingSh0uldBe1nVault", roles: [ { role: "root", db: "admin" } ]})
db.createUser(
{
    user: 'mongodbadmin', 
    pwd: 'Som3thingSh0uldBe1nVault', 
    roles: [{ role: 'read', db:'local'},{ role: 'userAdminAnyDatabase', db:'admin'},{ role: 'dbAdminAnyDatabase', db:'admin'},{ role: 'readWriteAnyDatabase', db:'admin'}]}
)
use miztiik_db
db.createUser( 
{ 
    user: "dms-user",
    pwd: "Som3thingSh0uldBe1nVault",
    roles: [ { role: "read", db: "local" }, "read"] 
})
EOF

mongo < mongo_create_admin_user.js

}

function configure_mongodb(){
# Increasing Ulimits
echo "* soft nofile 64000" >> /etc/security/limits.conf
echo "* hard nofile 64000" >> /etc/security/limits.conf
echo "* soft nproc 32000" >> /etc/security/limits.conf
echo "* hard nproc 32000" >> /etc/security/limits.conf
# echo "* soft nproc 32000" >> /etc/security/limits.d/90-nproc.conf
# echo "* hard nproc 32000" >> /etc/sesucurity/limits.d/90-nproc.conf

# Enabling MongoDB Public Access
sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf

# Creating Admin Users
# Not the best way, but for a quick demo, this is acceptable?
# db.updateUser( "reinventuser", {roles: ["readWrite", "dbAdmin"],db: "admin"})

# Enabling Replication
echo 'replication:
    replSetName: "rs0"' >> /etc/mongod.conf
sudo systemctl restart mongod
cat > 'mongo_pre_load.js' << "EOF"
rs.initiate( 
    {
        _id : "rs0",
        "version" : 1,
        members: [
            { 
                _id: 0, host: "localhost:27017" 
            }
        ]
    }
)
rs.initiate()
EOF


mongo < mongo_pre_load.js

# To Connect Remotely
# mongo -u kk -p YOUR-PASSWORD PUBLIC-IP/DB-NAME
# mongo -u mongodbadmin -p Som3thingSh0uldBe1nVault 54.1.151/miztiik_db
# mongo -u mongodbadmin -p Som3thingSh0uldBe1nVault 10.10.0.25/admin
# db.changeUserPassword("mongodbadmin@admin", "Som3thingSh0uldBe1nVault")

sudo systemctl restart mongod
# sudo mongod --replSet "rs0" --dbpath /var/lib/mongo --auth -port 27017 &
}


function install_cw_agent() {
# Installing AWS CloudWatch Agent FOR AMAZON LINUX RPM
agent_dir="/tmp/cw_agent"
cw_agent_rpm="https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm"
mkdir -p ${agent_dir} \
    && cd ${agent_dir} \
    && sudo yum install -y curl \
    && curl ${cw_agent_rpm} -o ${agent_dir}/amazon-cloudwatch-agent.rpm \
    && sudo rpm -U ${agent_dir}/amazon-cloudwatch-agent.rpm


cw_agent_schema="/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"

# PARAM_NAME="/stream-data-processor/streams/data_pipe/stream_name"
# a=$(aws ssm get-parameter --name "$PARAM_NAME" --with-decryption --query "Parameter.{Value:Value}" --output text)
# LOG_GROUP_NAME="/stream-data-processor/producers"

cat > '/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json' << "EOF"
{
"agent": {
    "metrics_collection_interval": 5,
    "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
},
"metrics": {
    "metrics_collected": {
    "mem": {
        "measurement": [
        "mem_used_percent"
        ]
    }
    },
    "append_dimensions": {
    "ImageId": "${aws:ImageId}",
    "InstanceId": "${aws:InstanceId}",
    "InstanceType": "${aws:InstanceType}"
    },
    "aggregation_dimensions": [
    [
        "InstanceId",
        "InstanceType"
    ],
    []
    ]
},
"logs": {
    "logs_collected": {
    "files": {
        "collect_list": [
        {
            "file_path": "/var/log/miztiik-automation**.log",
            "log_group_name": "/miztiik-automation",
            "timestamp_format": "%b %-d %H:%M:%S",
            "timezone": "Local"
        }
        ]
    }
    },
    "log_stream_name": "{instance_id}"
}
}
EOF

    # Configure the agent to monitor ssh log file
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:${cw_agent_schema} -s
    # Start the CW Agent
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status

    # Just in case we need to troubleshoot
    # cd "/opt/aws/amazon-cloudwatch-agent/logs/"
}

# Let the execution begin
# if [ $# -eq 0 ]; then
#   instruction
#   exit 1

install_libs
install_mongodb
configure_mongodb
install_cw_agent

