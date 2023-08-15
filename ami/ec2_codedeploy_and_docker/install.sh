#!/usr/bin/env bash
set -e
set -x

cloud-init status --wait

sudo cat /etc/lsb-release
uname -a

sudo apt-get update && \
sudo apt-get install -y \
  docker.io \
  jq \
  net-tools \
  python3-pip \
  ruby-full \
  sysstat \
  wget \
  zip

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
        unzip awscliv2.zip && \
        sudo ./aws/install && \
        rm -rf ./aws

if [ "$(/usr/bin/getent group | grep docker -c)" -eq 0 ]; then
  sudo groupadd docker
fi

sudo usermod -aG docker ubuntu

## Install CodeDeploy
wget https://aws-codedeploy-us-west-1.s3.us-west-1.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto


## Copy elastic ip address claim script
cat <<'EOF' > /tmp/claim_eip.sh
#!/usr/bin/env bash
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
INSTANCE_ID=`curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id`
if [ -z "$INSTANCE_ID" ]; then
    echo >&2 "Unable to fetch the instance ID from IMDSv2"
    exit 2
fi

## Fetched from tags
EIP_POOL_NAME=$(/usr/local/bin/aws ec2 describe-tags --filter Name=resource-id,Values="${INSTANCE_ID}" --region=us-west-1 | jq -r ".Tags[] | select(.Key == \"EIP_POOL_NAME\" ) | .Value")
if [ -z "$EIP_POOL_NAME" ]; then
  echo >&2 "No EIP_POOL_NAME tag was set!"
  exit 2
fi

function maybe_claim_eip {
  local ALLOCATION_ID
  ALLOCATION_ID=""
  while [[ -z ${ALLOCATION_ID} ]]
  do
    ALLOCATION_ID=`/usr/local/bin/aws ec2 describe-addresses --region us-west-1 --filters="Name=tag:Name,Values=${EIP_POOL_NAME}" | jq -r '.Addresses[] | "\(.InstanceId) \(.AllocationId)"' | grep null | awk '{print $2}' | xargs shuf -n1 -e`
    if [[ ! -z ${ALLOCATION_ID} ]]; then
      /usr/local/bin/aws ec2 associate-address --region=us-west-1 --instance-id=${INSTANCE_ID} --allocation-id=${ALLOCATION_ID} --no-allow-reassociation

      if [ $? -eq 0 ]; then
          echo >&2 "${ALLOCATION_ID} has been associated to this instance."
          break;
      else
        echo >&2 "There was an error attaching the elastic IP to this instance."
        ALLOCATION_ID=""
        sleep 3
      fi
    else
      echo >&2 "No available EIPs exist with the ${EIP_POOL_NAME} Name tag. Sleeping for 10 more seconds."
      sleep 10
    fi
  done
}

echo >&2 "No Elastic IP associated with this instance. Attempting to fetch one from the Elastic IP addresses with a name of, '${EIP_POOL_NAME}'"
maybe_claim_eip
sleep 3
PUBLIC_IPV4=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 -H "X-aws-ec2-metadata-token: $TOKEN")
EOF
sudo mv /tmp/claim_eip.sh /usr/local/bin/claim_eip.sh
sudo chmod 0755 /usr/local/bin/claim_eip.sh

cat <<'EOF' > /tmp/claim_eip
@reboot root /usr/local/bin/claim_eip.sh 2>&1 | logger -t claim_eip
EOF
sudo mv /tmp/claim_eip /etc/cron.d/claim_eip

#The logging for docker Configuring a Syslog Server that applies to all instances
#the tagging script is in the user-data scripts per env.
## Copy docker-daemon.conf for logs
cat <<'EOF' > /tmp/49-docker-daemon.conf
$template DockerLogs, "/var/log/docker/daemon.log"
if $programname startswith 'dockerd' then -?DockerLogs
& stop
EOF

sudo mv /tmp/49-docker-daemon.conf /etc/rsyslog.d/49-docker-daemon.conf

cat <<'EOF' > /tmp/48-docker-containers.conf
$template DockerContainerLogs,"/var/log/docker/%hostname%_%syslogtag:R,ERE,1,ZERO:.*container_name/([^\[]+)--end%.log"
if $syslogtag contains 'container_name'  then -?DockerContainerLogs
& stop
EOF
sudo mv /tmp/48-docker-containers.conf /etc/rsyslog.d/48-docker-containers.conf

#Configuring Docker for Sending Logs to Syslog

cat <<'EOF' > /tmp/daemon.json
{
  "log-driver": "syslog",
  "log-opts": {
    "tag": "{{.ImageName}}/{{.Name}}/{{.ID}}",
    "labels": "dev",
    "syslog-facility": "daemon"
  }
}
EOF
sudo mv /tmp/daemon.json /etc/docker/daemon.json

sudo systemctl daemon-reload

sudo systemctl restart docker

sudo service rsyslog restart


