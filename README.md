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

#### VMs setup
Linux environment details.
`root@pgvm1:~# lsb_release -a</br>
No LSB modules are available.`
`Distributor ID: Ubuntu`
`Description:    Ubuntu 18.04.5 LTS`
`Release:        18.04`
`Codename:       bionic`



