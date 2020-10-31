#!/bin/bash
#Description: Setup Environment
#Install PostgreSQL12, Patroni, pgbackrest
# 1. System update
# 2. Install PostgreSQL 12
# 3.Install Patroni
# 4. Install pgbackrest

#set -x

echo "System update"
sleep 2
apt update
apt-get upgrade -y
echo "Completed system update"
sleep 1

echo "Adding latest PG repository"
sleep 2
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
echo "Completed adding latest PG repository"
sleep 1

echo "Installing PostgreSQL 12"
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

echo "Installing pgbackrest"
sleep 2
apt -y install perl libtime-hires-perl libdigest-sha-perl libjson-pp-perl
apt-get install -y pgbackrest
echo "Completed installing pgbackrest"
sleep 1

