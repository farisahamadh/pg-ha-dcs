#!/bin/bash
#Description: Setup Environment
#Install Patroni

#set -x

echo "System update"
sleep 2
apt update
apt-get upgrade -y
echo "Completed system update"
sleep 1

echo "Installing & Confifuring Patroni dependencies"
sleep 2
sudo ln -s /usr/lib/postgresql/12/bin/* /usr/sbin/
apt -y install python python-pip jq
pip install --upgrade setuptools
pip install psycopg2-binary
apt -y install python-psycopg2
apt -y install python3-psycopg2
echo "Completed installing Patroni dependencies"
sleep 1

echo "Installing Patroni"
sleep 2
#pip install patroni[dependencies]
pip install patroni[etcd]
echo "Completed installing Patroni"
sleep 1


