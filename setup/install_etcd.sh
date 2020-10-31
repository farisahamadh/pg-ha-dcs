#!/bin/bash
#Description: Setup Environment
#Install etcd


#set -x

echo "1. System update"
sleep 2
apt update
apt-get upgrade -y
echo "Completed system update"
sleep 1

echo "Installing etcd"
sleep 2
pip install python-etcd
apt -y install etcd
echo "Completed installing etcd"
sleep 1
