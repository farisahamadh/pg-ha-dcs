#!/bin/bash
#Description: Setup Environment
#Install PostgreSQL12, Patroni
# 1. System update
# 2. Install PostgreSQL 12


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
