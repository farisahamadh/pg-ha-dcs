# Postgres HA setup with Patroni
This document will explain the steps complete PostgreSQL HA setup with Patroni

### Test environmenT:
|VM Name |	Purpose	| IP address|
|---|---|---|
|pgvm1 |	Postgres, Patroni	| 50.51.52.81|
|pgvm2	| Postgres, Patroni	| 50.51.52.82|
|pgvm3	| Postgres, Patroni |	50.51.52.83|
|pgvm4	| etcd |	50.51.52.84|
|pgvm5 |	HAProxy	| 50.51.52.85|
