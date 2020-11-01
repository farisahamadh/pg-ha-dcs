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
|pgvm7 |	Postgres, Patroni	| 50.51.52.87| New vm for bootstrapping from backup |
|pgvm8 |	Postgres, Patroni	| 50.51.52.88| standby for new PG cluster |

### VMs setup
OS release version of all the Linux VMs used for this setup.</br>
`root@pgvm1:~# lsb_release -a`</br>
`No LSB modules are available.`</br>
`Distributor ID: Ubuntu`</br>
`Description:    Ubuntu 18.04.5 LTS`</br>
`Release:        18.04`</br>
`Codename:       bionic`</br></br>


Execute following scripts to install the required packages.
1. Install Postgres 12, Patroni on VMs pgvm1, pgvm2 & pgvm3 by executing the following scripts.</br>
[setup/install_postgres.sh](https://github.com/farisahamadh/pgsql-ha/blob/main/setup/install_postgres.sh)</br>
[setup/install_patroni.sh](https://github.com/farisahamadh/pgsql-ha/blob/main/setup/install_patroni.sh)</br>

2. Install etcd on pgvm4 by executing the following script.</br>
[setup/install_etcd.sh](https://github.com/farisahamadh/pgsql-ha/blob/main/setup/install_etcd.sh)</br>

3. Install HAProxy on pgvm5 by executing the following script.</br>
[setup/install_haproxy.sh](https://github.com/farisahamadh/pgsql-ha/blob/main/setup/install_HA.sh)</br>

4. Install pgbackrest on pgvm1,pgvm2,pgvm3,pgvm6 by executing the following script.</br>
[setup/install_pgbackrest.sh](https://github.com/farisahamadh/pgsql-ha/blob/main/setup/install_pgbackrest.sh)</br>

### Configuration
##### etcd
etcd is an open source distributed key-value store used to hold and manage the critical information that distributed systems need to keep running. Patroni makes use of  etcd to keep the Postgres cluster up and running.

On pgvm4, update etcd configuration  /etc/default/etcd using [config/pgvm4/etcd](https://github.com/farisahamadh/pgsql-ha/tree/main/config/pgvm4/etcd) with following values.

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
pgvm1: /etc/patroni.yml using [config/pgvm1/patroni.yml](https://github.com/farisahamadh/pgsql-ha/blob/main/config/pgvm1/patroni.yml)</br>
pgvm2: /etc/patroni.yml using [config/pgvm1/patroni.yml](https://github.com/farisahamadh/pgsql-ha/blob/main/config/pgvm2/patroni.yml)</br>
pgvm3: /etc/patroni.yml using [config/pgvm1/patroni.yml](https://github.com/farisahamadh/pgsql-ha/blob/main/config/pgvm3/patroni.yml)</br>

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

Configure HAProxy parameter file `/etc/haproxy/haproxy.cfg` using [config/pgvm5/haproxy.cfg](https://github.com/farisahamadh/pgsql-ha/blob/main/config/pgvm5/haproxy.cfg)

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

On each postgres host (pgvm1, pgvm2 and pgvm3), create the pgbackrest.conf to point to repository server using the following files.

pgvm1: /etc/pgbackrest/pgbackrest.conf using [config/pgvm1/pgbackrest.conf](https://github.com/farisahamadh/pgsql-ha/blob/main/config/pgvm1/pgbackrest.conf)</br>
pgvm2: /etc/pgbackrest/pgbackrest.conf using [config/pgvm2/pgbackrest.conf](https://github.com/farisahamadh/pgsql-ha/blob/main/config/pgvm2/pgbackrest.conf)</br>
pgvm2: /etc/pgbackrest/pgbackrest.conf using [config/pgvm2/pgbackrest.conf](https://github.com/farisahamadh/pgsql-ha/blob/main/config/pgvm3/pgbackrest.conf)</br>

Modify patroni YAML configuration file to set archive locations to pgbackrest. Make sure following changes are made in YAML files.

>postgresql: </br>
>  listen: "0.0.0.0:5432"</br>
>parameters:</br>
>    archive_mode: "on"</br>
>    archive_command: 'pgbackrest --stanza=main archive-push %p'</br>

Restart Patroni and PG cluster using the modified YAML files available at,</br>
pgvm1: /etc/patroni1.yml using [config/pgvm1/patroni1.yml](https://github.com/farisahamadh/pgsql-ha/blob/main/config/pgvm1/patroni1.yml)</br>
pgvm2: /etc/patroni1.yml using [config/pgvm2/patroni1.yml](https://github.com/farisahamadh/pgsql-ha/blob/main/config/pgvm2/patroni1.yml)</br>
pgvm3: /etc/patroni1.yml using [config/pgvm3/patroni1.yml](https://github.com/farisahamadh/pgsql-ha/blob/main/config/pgvm3/patroni1.yml)</br>


On the backup repository server, create pgbackrest configuration file at `/etc/pgbackrest/pgbackrest.conf` using the script [config/pgvm6/pgbackrest.conf](https://github.com/farisahamadh/pgsql-ha/tree/main/config/pgvm6). Make sure that the repository location defined in repo1-path is created and have right permission.

This config file defines all 3  postgres instances are locations, how it is archived, and how it is backed up. It is known as a <b>stanza</b>. In this example "main" is defined as stanza name in the config file.

When all the configurations are set, it is time to create the <b>stanza</b> "main" on the backup repository host pgvm6.

`postgres@pgvm6:~$ pgbackrest --stanza=main --log-level-console=info stanza-create`</br>
`2020-10-31 09:06:28.377 P00   INFO: stanza-create command begin 2.30: --log-level-console=info --pg1-host=50.51.52.81 --pg2-host=50.51.52.82 --pg3-host=50.51.52.83 --pg1-path=/var/lib/postgresql/data --pg2-path=/var/lib/postgresql/data --pg3-path=/var/lib/postgresql/data --pg1-port=5432 --pg2-port=5432 --pg3-port=5432 --pg1-socket-path=/var/run/postgresql --pg2-socket-path=/var/run/postgresql --pg3-socket-path=/var/run/postgresql --repo1-path=/var/lib/pgbackrest --stanza=main
2020-10-31 09:06:33.044 P00   INFO: stanza-create command end: completed successfully (4668ms)`</br>

Check pgbackrest configuration on all 3 Postgres nodes.

<b>pgvm1</b></br>
<pre>postgres@pgvm1:~$ pgbackrest --stanza=main --log-level-console=info check
2020-10-31 09:09:12.636 P00   INFO: check command begin 2.30: --log-level-console=info --log-level-file=detail --pg1-path=/var/lib/postgresql/data --pg1-port=5432 --pg1-socket-path=/var/run/postgresql --repo1-host=50.51.52.86 --repo1-host-user=postgres --stanza=main
2020-10-31 09:09:15.579 P00   INFO: WAL segment 000000130000000000000012 successfully archived to '/var/lib/pgbackrest/archive/main/12-1/0000001300000000/000000130000000000000012-a46534b247e80690628412fec6db0c443cbabea2.gz
2020-10-31 09:09:15.681 P00   INFO: check command end: completed successfully (3046ms)</pre></br>

<b>pgvm2</b></br>
<pre>postgres@pgvm2:~$ pgbackrest --stanza=main --log-level-console=info check
2020-10-31 09:10:15.763 P00   INFO: check command begin 2.30: --log-level-console=info --log-level-file=detail --pg1-path=/var/lib/postgresql/data --pg1-port=5432 --pg1-socket-path=/var/run/postgresql --repo1-host=50.51.52.86 --repo1-host-user=postgres --stanza=main
2020-10-31 09:10:17.269 P00   INFO: switch wal not performed because this is a standby
2020-10-31 09:10:17.370 P00   INFO: check command end: completed successfully (1608ms)</pre></br>

<b>pgvm3</b></br>
<pre>postgres@pgvm3:~$ pgbackrest --stanza=main --log-level-console=info check
2020-10-31 05:10:59.648 P00   INFO: check command begin 2.30: --log-level-console=info --log-level-file=detail --pg1-path=/var/lib/postgresql/data --pg1-port=5432 --pg1-socket-path=/var/run/postgresql --repo1-host=50.51.52.86 --repo1-host-user=postgres --stanza=main
2020-10-31 05:11:01.073 P00   INFO: switch wal not performed because this is a standby
2020-10-31 05:11:01.179 P00   INFO: check command end: completed successfully (1532ms)</pre></br>

Note the difference in output. The <b>WAL log</b> will only be archived from the primary.


Now, its time to run the first pgbackrest backup. Execute the following command on backup repository server.
<pre>postgres@pgvm6:~$ pgbackrest --log-level-console=info --stanza=main backup
2020-10-31 09:12:40.286 P00   INFO: backup command begin 2.30: --log-level-console=info --pg1-host=50.51.52.81 --pg2-host=50.51.52.82 --pg3-host=50.51.52.83 --pg1-path=/var/lib/postgresql/data --pg2-path=/var/lib/postgresql/data --pg3-path=/var/lib/postgresql/data --pg1-port=5432 --pg2-port=5432 --pg3-port=5432 --pg1-socket-path=/var/run/postgresql --pg2-socket-path=/var/run/postgresql --pg3-socket-path=/var/run/postgresql --repo1-path=/var/lib/pgbackrest --repo1-retention-full=2 --stanza=main --start-fast
WARN: no prior backup exists, incr backup has been changed to full
2020-10-31 09:12:44.504 P00   INFO: execute non-exclusive pg_start_backup(): backup begins after the requested immediate checkpoint completes
2020-10-31 09:12:45.019 P00   INFO: backup start archive = 000000130000000000000014, lsn = 0/14000028
2020-10-31 09:12:47.133 P01   INFO: backup file 50.51.52.81:/var/lib/postgresql/data/base/13398/1255 (632KB, 2%) checksum 1736b758f724711a283690fd11db4dc488629297
2020-10-31 09:12:47.168 P01   INFO: backup file 50.51.52.81:/var/lib/postgresql/data/base/13397/1255 (632KB, 5%) checksum 4cd8fb7fe980a235613b2d1a8b8fbc5abe7fa96b
2020-10-31 09:12:47.202 P01   INFO: backup file 50.51.52.81:/var/lib/postgresql/data/base/1/1255 (632KB, 7%) checksum 4cd8fb7fe98
.
.
.
.
.
lines truncated
.
.
2020-10-31 09:12:57.917 P01   INFO: backup file 50.51.52.81:/var/lib/postgresql/data/base/1/13235 (0B, 100%)
2020-10-31 09:12:57.921 P00   INFO: full backup size = 23.5MB
2020-10-31 09:12:57.921 P00   INFO: execute non-exclusive pg_stop_backup() and wait for all WAL segments to archive
2020-10-31 09:12:58.131 P00   INFO: backup stop archive = 000000130000000000000014, lsn = 0/14000138
2020-10-31 09:12:58.133 P00   INFO: check archive for segment(s) 000000130000000000000014:000000130000000000000014
2020-10-31 09:12:59.480 P00   INFO: new backup label = 20201031-091244F
2020-10-31 09:12:59.545 P00   INFO: backup command end: completed successfully (19260ms)
2020-10-31 09:12:59.546 P00   INFO: expire command begin 2.30: --log-level-console=info --pg1-host=50.51.52.81 --pg2-host=50.51.52.82 --pg3-host=50.51.52.83 --repo1-path=/var/lib/pgbackrest --repo1-retention-full=2 --stanza=main
2020-10-31 09:12:59.767 P00   INFO: expire command end: completed successfully (222ms)
postgres@pgvm6:~$</pre></br>


##### Restore from pgbackrest and bootstrap new patroni cluster
The following section will explain steps to perform restore on a different machine pgvm7 and setup a replica instance on pgvm8 using patroni.

Install Postgres 12, Patroni and pgbackrest on VMs pgvm7 & pgvm8 by executing the following scripts.</br>
[setup/install_postgres.sh](https://github.com/farisahamadh/pgsql-ha/blob/main/setup/install_postgres.sh)</br>
[setup/install_patroni.sh](https://github.com/farisahamadh/pgsql-ha/blob/main/setup/install_patroni.sh)</br>
[setup/install_pgbackrest.sh](https://github.com/farisahamadh/pgsql-ha/blob/main/setup/install_pgbackrest.sh)</br>

Create configuration directories for pgbackrest on VMs pgvm7 and pgvm8 using the script [setup/create_pgbackrest_dirs.sh](https://github.com/farisahamadh/pgsql-ha/blob/main/setup/create_pgbackrest_dirs.sh)

On new host pgvm7, create the pgbackrest.conf to point to stanza <b>main</b> in repository server .

pgvm7: /etc/pgbackrest/pgbackrest.conf using [config/pgvm8/pgbackrest.conf](https://github.com/farisahamadh/pgsql-ha/blob/main/config/pgvm7/pgbackrest.conf)</br>

Now the new machine pgvm7 is ready for restore and run the following command to start restore.

<pre>
postgres@pgvm7:~$ pgbackrest --stanza=main --log-level-console=info restore
2020-11-01 04:43:27.516 P00   INFO: restore command begin 2.30: --log-level-console=info --log-level-file=off --pg1-path=/var/lib/postgresql/data --repo1-host=50.51.52.86 --repo1-host-user=postgres --stanza=main
2020-11-01 04:43:28.500 P00   INFO: restore backup set 20201031-091244F
2020-11-01 04:43:29.482 P01   INFO: restore file /var/lib/postgresql/data/base/13398/1255 (632KB, 2%) checksum 1736b758f724711a283690fd11db4dc488629297
2020-11-01 04:43:29.503 P01   INFO: restore file /var/lib/postgresql/data/base/13397/1255 (632KB, 5%) checksum 4cd8fb7fe980a235613b2d1a8b8fbc5abe7fa96b
2020-11-01 04:43:29.522 P01   INFO: restore file /var/lib/postgresql/data/base/1/1255 (632KB, 7%) checksum 4cd8fb7fe980a235613b2d
.
.
.
.
lines truncated
.
.
.
2020-11-01 04:43:37.635 P01   INFO: restore file /var/lib/postgresql/data/base/1/13235 (0B, 100%)
2020-11-01 04:43:37.664 P00   INFO: write updated /var/lib/postgresql/data/postgresql.auto.conf
2020-11-01 04:43:37.671 P00   INFO: restore global/pg_control (performed last to ensure aborted restores cannot be started)
2020-11-01 04:43:37.777 P00   INFO: restore command end: completed successfully (10263ms)
</pre>



##### Monitoring






