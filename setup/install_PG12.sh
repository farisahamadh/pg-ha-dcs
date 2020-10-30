#!/bin/bash
#Description: Setup Environment
# 1. System update
# 2. Install PostgreSQL 12
# 3.Install Patroni
# 4. Install etcd
# 5. Install HAProxy

#set -x

echo "1. System update"
sleep 2
apt update
apt-get upgrade -y
echo "Completed system update"
sleep 1

echo "2. Adding latest PG repository"
sleep 2
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
echo "Completed adding latest PG repository"
sleep 1

echo "2. Installing PostgreSQL 12"
sleep 2
apt -y install postgresql-12 postgresql-client-12
sleep 1
echo "Completed installing PostgreSQL 12"
sleep 1
echo "Stop default PG instance"
sleep 2
systemctl stop postgresql
echo "Finished stopping PG instance"
sleep 1

echo "3. Installing & Confifuring Patroni dependencies"
sleep 2
sudo ln -s /usr/lib/postgresql/12/bin/* /usr/sbin/
apt -y install python python-pip jq
pip install --upgrade setuptools
pip install psycopg2-binary
apt -y install python-psycopg2   
apt -y install python3-psycopg2  
apt -y install perl libtime-hires-perl libdigest-sha-perl libjson-pp-perl
echo "Completed installing Patroni dependencies"
sleep 1

echo "3. Installing Patroni"
sleep 2
#pip install patroni[dependencies]
pip install patroni[etcd]
echo "Completed installing Patroni"
sleep 1

echo "4. Installing etcd"
sleep 2
pip install python-etcd
apt -y install etcd
echo "Completed installing etcd"
sleep 1

echo "5. Installing HA Proxy"
sleep 2
apt install -y haproxy 
echo "Completed installing HA Proxy"
sleep 1

