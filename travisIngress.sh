#!/usr/bin/env bash

set -e

# Abort if the action, security group ID or port are not provided
if [ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ] ; then
    echo "You must set an authorize or revoke option, a security group ID and a port number"
    echo "Example: travisIngress.sh authorize|revoke sg-1234567890 22"
    exit
fi

# Determine if the action is to authorize or revoke
if [ "$1" != "" ]; then
    if [ $1 = "authorize" ]; then
        SECURITY_GROUP_ACTION="authorize-security-group-ingress"
    else
        SECURITY_GROUP_ACTION="revoke-security-group-ingress"
    fi
fi

# Get the Security Group ID from the command line parameter
if [ "$2" != "" ]; then
    SECURITY_GROUP_ID=${2}
fi

# Get the Port to open/close in the Security group
if [ "$3" != "" ]; then
    PORT_NUMBER=${3}
fi

# Get the IP addresses from Travis
TRAVIS_IPADDRESSES=`curl -s https://dnsjson.com/nat.travisci.net/A.json | jq -c '.results.records|sort'`

# trim off the [ ]
IPADDRESSES=${TRAVIS_IPADDRESSES#"["}
IPADDRESSES=${IPADDRESSES%"]"}

# Create an array of IPs
IPADDRESSES_ARRAY=$(echo ${IPADDRESSES} | tr "\",\"" "\n")

# Loop over IPs add them to the Security Group
for IP in ${IPADDRESSES_ARRAY}
do
    aws ec2 ${SECURITY_GROUP_ACTION} --region us-east-1 --group-id ${SECURITY_GROUP_ID} --protocol tcp --port ${PORT_NUMBER} --cidr ${IP}/32
done;