#!/bin/bash
#Description: Setup Environment
#Install HA Proxy
#set -x

echo "System update"
sleep 2
apt update
apt-get upgrade -y
echo "Completed system update"
sleep 1

echo "Installing HA Proxy"
sleep 2
apt install -y haproxy
echo "Completed installing HA Proxy"
sleep 1

