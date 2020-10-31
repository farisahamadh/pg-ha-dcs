# Postgres HA setup with Patroni
This document will walk through the steps to perform PostgreSQL HA setup (1 master and 2 standbys) with Patroni. 

### Environment details - 6 Linux VMs of following
|VM Name |	Purpose	| IP address| Description |
|---|---|---|-----|
|pgvm1 |	Postgres, Patroni	| 50.51.52.81|Postgresql Master node | 
|pgvm2	| Postgres, Patroni	| 50.51.52.82|Postgresql standby node 1 | 
|pgvm3	| Postgres, Patroni |	50.51.52.83|Postgresql standby node 2 | 
|pgvm4	| etcd |	50.51.52.84| Distributed configuration store |
|pgvm5 |	HAProxy	| 50.51.52.85| Single endpoint for connecting to the cluster's leader |
|pgvm6 |	pgbackrest repository	| 50.51.52.86| Backup repository server |

### VMs setup
OS release version of all the Linux VMs used for this setup.</br>
`root@pgvm1:~# lsb_release -a`</br>
`No LSB modules are available.`</br>
`Distributor ID: Ubuntu`</br>
`Description:    Ubuntu 18.04.5 LTS`</br>
`Release:        18.04`</br>
`Codename:       bionic`</br></br>


Execute following scripts to install the required packages.
1. Install Postgres 12, Patroni on VMs pgvm1, pgvm2 & pgvm3 by executing the following scripts.
[setup/install_postgres.sh](https://github.com/farisahamadh/pgsql-ha/blob/main/setup/install_postgres.sh)</br>
[setup/install_patroni.sh](https://github.com/farisahamadh/pgsql-ha/blob/main/setup/install_patroni.sh)</br>

2. Install etcd on pgvm4 by executing the following script.
[setup/install_etcd.sh](https://github.com/farisahamadh/pgsql-ha/blob/main/setup/install_etcd.sh)</br>

3. Install HAProxy on pgvm5 by executing the following script.
[setup/install_haproxy.sh](https://github.com/farisahamadh/pgsql-ha/blob/main/setup/install_HA.sh)</br>

4. Install pgbackrest on pgvm1,pgvm2,pgvm3,pgvm6 by executing the following script.
[setup/install_pgbackrest.sh](https://github.com/farisahamadh/pgsql-ha/blob/main/setup/install_pgbackrest.sh)</br>

### Configuration
##### etcd
etcd is an open source distributed key-value store used to hold and manage the critical information that distributed systems need to keep running. Patroni makes use of  etcd to keep the Postgres cluster up and running.

On pgvm4, update etcd configuration  [/etc/default/etcd](https://github.com/farisahamadh/pgsql-ha/tree/main/config/pgvm4/etcd) with following values.
`ETCD_LISTEN_PEER_URLS="http://50.51.52.84:2380"`</br>
`ETCD_LISTEN_CLIENT_URLS="http://localhost:2379,http://50.51.52.84:2379"`</br>
`ETCD_INITIAL_ADVERTISE_PEER_URLS="http://50.51.52.84:2380"`</br>
`ETCD_INITIAL_CLUSTER="etcd=http://50.51.52.84:2380"`</br>
`ETCD_INITIAL_CLUSTER_STATE="new"`</br>
`ETCD_INITIAL_CLUSTER_TOKEN="etcd-pg-cluster"`</br>
`ETCD_ADVERTISE_CLIENT_URLS="http://50.51.52.84:2379"`</br>

Save and close the file when fiinished and start etcd with the below command.
`systemctl start etcd`</br>

Check the status of of etcd with following commands.
`root@pgvm4:~# systemctl status etcd`</br>
`● etcd.service - etcd - highly-available key value store`</br>
`   Loaded: loaded (/lib/systemd/system/etcd.service; disabled; vendor preset: enabled)`</br>
`   Active: active (running) since Sat 2020-10-31 04:47:35 UTC; 5h 49min ago`</br>
`     Docs: https://github.com/coreos/etcd`</br>
`           man:etcd`</br>
` Main PID: 1582 (etcd)`</br>
`    Tasks: 11 (limit: 4632)`</br>
`   CGroup: /system.slice/etcd.service`</br>
`           └─1582 /usr/bin/etcd`</br>

`root@pgvm4:~# etcdctl cluster-health`</br>
`member 8e9e05c52164694d is healthy: got healthy result from http://50.51.52.84:2379`</br>
`cluster is healthy` </br>

`root@pgvm4:~# etcdctl member list`</br>
`8e9e05c52164694d: name=pgvm4 peerURLs=http://localhost:2380 clientURLs=http://50.51.52.84:2379 isLeader=true`</br>


##### Patroni and Potgresql

Create Patroni configuration files for pgvm1,pgvm2 and pgvm3 and ensure following configuration parameters are refering the correct server. 
For example,

> name:<b>pgvm1</b></br>
>restapi:</br>
>   listen: <b>50.51.52.81:8008</b> </br>
>   connect_address: <b>50.51.52.81:8008</b> </br>
>etcd:</br>
>    host: <b>50.51.52.84:2379</b></br>
>bootstrap:</br>
>    dcs:</br>
>        <b>ttl: 30</b>,/br>
>  postgresql:</br>
>  listen: <b>50.51.52.81:5432</b> </br>
>  connect_address: <b>50.51.52.81:5432</b> </br>

Patroni configuration is stored in the DCS (Distributed Configuration Store), etcd in this case and these options are set in DCS at any time.

Time to Live(ttl) is defined as 30 seconds. ie, CS will elect a new leader node(master)if primary is not reachable for 30 seconds.

Complete list of parameters and files used in this setup are as follows.</br>
pgvm1: [/etc/patroni.yml](https://github.com/farisahamadh/pgsql-ha/blob/main/config/pgvm1/patroni.yml)</br>
pgvm2: [/etc/patroni.yml](https://github.com/farisahamadh/pgsql-ha/blob/main/config/pgvm2/patroni.yml)</br>
pgvm3: [/etc/patroni.yml](https://github.com/farisahamadh/pgsql-ha/blob/main/config/pgvm3/patroni.yml)</br>

Start patroni when the parameters are ready. Patroni will create a new PG cluster and the result from <b>pgvm1, pgvm2</b> is follows.

`postgres@pgvm1:~$patroni /etc/patroni.yml > patronilogs/patroni_member_1.log 2>&1 &` </br>

and

`postgres@pgvm2:~$patroni /etc/patroni.yml > patronilogs/patroni_member_1.log 2>&1 &` </br>

`postgres@pgvm2:~$ patronictl -c /etc/patroni.yml list`</br>
`+ Cluster: postgres (6889331455358453954) -+----+-----------+`</br>
`| Member | Host        | Role    | State   | TL | Lag in MB |`</br>
`+--------+-------------+---------+---------+----+-----------+`</br>
`| pgvm1  | 50.51.52.81 | Leader  | running |  1 |           |`</br>
`| pgvm2  | 50.51.52.82 | Replica | running |  1 |       0.0 |`</br>
`+--------+-------------+---------+---------+----+-----------+`</br>

Restart pgvm1 and start patroni. Patroni will do the failover with the help of etcd. Notice that the timeline(TL) is incremented by 1 due to failover.

`postgres@pgvm2:~$ patronictl -c /etc/patroni.yml list`</br>
`+ Cluster: postgres (6889331455358453954) -+----+-----------+`</br>
`| Member | Host        | Role    | State   | TL | Lag in MB |`</br>
`+--------+-------------+---------+---------+----+-----------+`</br>
`| pgvm1  | 50.51.52.81 | Replica  | running |  2 |           |`</br>
`| pgvm2  | 50.51.52.82 | Leader   | running |  2 |       0.0 |`</br>
`+--------+-------------+---------+---------+----+-----------+`</br>

Bootstrapping a new node or adding further standby instance(s) can be done by modifying key parameters in patroni.yml in the new host(pgvm3).

`postgres@pgvm3:~$patroni /etc/patroni.yml > patronilogs/patroni_member_1.log 2>&1 &`

`postgres@pgvm2:~$ patronictl -c /etc/patroni.yml list`</br>
`+ Cluster: postgres (6889331455358453954) -+----+-----------+`</br>
`| Member | Host        | Role    | State   | TL | Lag in MB |`</br>
`+--------+-------------+---------+---------+----+-----------+`</br>
`| pgvm1  | 50.51.52.81 | Replica | running |  3 |       0.0 |`</br>
`| pgvm2  | 50.51.52.82 | Leader  | running |  3 |           |`</br>
`| pgvm3  | 50.51.52.83 | Replica | running |  3 |       0.0 |`</br>
`+--------+-------------+---------+---------+----+-----------+`</br>

##### HAProxy
When developing an application that uses a database, it can be cumbersome to keep track of the database endpoints if they keep changing. Using HAProxy simplifies this by giving a single endpoint to which you can connect the application.

HAProxy forwards the connection to whichever node is currently the master. It does this using a REST endpoint that Patroni provides. Patroni ensures that, at any given time, only the master Postgres node will appear as online, forcing HAProxy to connect to the correct node.

Install HAProxy on pgvm5 using the script [setup/install_HA.sh](https://github.com/farisahamadh/pgsql-ha/tree/main/setup) 

Configure HAProxy parameter file with the values located at [/etc/haproxy/haproxy.cfg](https://github.com/farisahamadh/pgsql-ha/blob/main/config/pgvm5/haproxy.cfg)

Start HAProxy:
`root@pgvm5:# systemctl start haproxy`</br>
`root@pgvm5:~# systemctl status haproxy`</br>
`● haproxy.service - HAProxy Load Balancer`</br>
`   Loaded: loaded (/lib/systemd/system/haproxy.service; enabled; vendor preset: enabled)`</br>
`   Active: active (running) since Sat 2020-10-31 11:53:15 UTC; 3s ago`</br>
`     Docs: man:haproxy(1)`</br>
`           file:/usr/share/doc/haproxy/configuration.txt.gz`</br>
`  Process: 2988 ExecStartPre=/usr/sbin/haproxy -f $CONFIG -c -q $EXTRAOPTS (code=exited, status=0/SUCCESS)`</br>
` Main PID: 2998 (haproxy)`</br>
`    Tasks: 2 (limit: 4632)`</br>
`   CGroup: /system.slice/haproxy.service`</br>
`           ├─2998 /usr/sbin/haproxy -Ws -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid`</br>
`           └─3000 /usr/sbin/haproxy -Ws -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid`</br>
` `
`Oct 31 11:53:15 pgvm5 systemd[1]: Starting HAProxy Load Balancer...`</br>
`Oct 31 11:53:15 pgvm5 haproxy[2998]: Proxy stats started.`</br>
`Oct 31 11:53:15 pgvm5 haproxy[2998]: Proxy stats started.`</br>
`Oct 31 11:53:15 pgvm5 haproxy[2998]: Proxy postgres started.`</br>
`Oct 31 11:53:15 pgvm5 haproxy[2998]: Proxy postgres started.`</br>
`Oct 31 11:53:15 pgvm5 systemd[1]: Started HAProxy Load Balancer.`</br>

Test connectivity via HAProxy
`postgres@pgvm5:~$ psql -h 50.51.52.85 -p 5000 -U postgres`</br>
`Password for user postgres:`</br>
`psql (12.4 (Ubuntu 12.4-1.pgdg18.04+1))`</br>
`Type "help" for help.`</br>
` `</br>
`postgres=# \conninfo`</br>
`You are connected to database "postgres" as user "postgres" on host "50.51.52.85" at port "5000".`</br>
`postgres=#`</br>

##### Backup
Identifying and connecting to primary for backing up database is the biggest challenge in a replicated enviroment. PgBackrest will automatically determine which postgres instance is primary and will take the backup accordingly from there.

Install pgbackrest using the supplied script [setup/install_pgbackrest.sh](https://github.com/farisahamadh/pgsql-ha/blob/main/setup/install_pgbackrest.sh) on VMs pgvm1, pgvm2, pgvm3 and dedicated backup repository server pgvm6.

Exchange ssh keys to allow password-less login between all 4 hosts. 

Create configuration directories required for pgbackrest on VMs pgvm1, pgvm2 and pgvm3 using the script [setup/create_pgbackrest_dirs.sh](https://github.com/farisahamadh/pgsql-ha/blob/main/setup/create_pgbackrest_dirs.sh)

On the backup repository server, create pgbackrest configuration file at /etc/pgbackrest/pgbackrest.conf using the script [config/pgvm6/pgbackrest.conf](https://github.com/farisahamadh/pgsql-ha/tree/main/config/pgvm6). Make sure that the repository location defined in repo1-path is created and have right permission.

This config file defines all 3  postgres instances are locations, how it is archived, and how it is backed up. It is known as a <b>stanza</b>. In this example "main" is defined as stanza name in the config file.













