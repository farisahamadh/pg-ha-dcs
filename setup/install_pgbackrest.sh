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

echo "Retrieving pgbackrest source code from github"
sleep 2
wget https://github.com/pgbackrest/pgbackrest/archive/release/2.30.zip
unzip 2.30.zip
echo "Installing build dependencies"
apt-get -y install make gcc libpq-dev libssl-dev libxml2-dev pkg-config liblz4-dev libzstd-dev libbz2-dev libz-dev
apt -y install perl libtime-hires-perl libdigest-sha-perl libjson-pp-perl
apt-get -y install postgresql-client libxml2
cd pgbackrest-release-2.30/src && ./configure && make
cp pgbackrest /usr/bin/pgbackrest
chmod 755 /usr/bin/pgbackrest
echo "Completed pgbackrest installation"
sleep 1
