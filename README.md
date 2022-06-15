# Failover Issue

This folder attempts to minimally reproduce https://github.com/bitnami/bitnami-docker-postgresql-repmgr/issues/122

The `.yaml` files have a k8s config to run the deployment to reproduce the issue.

The [`simulate-failover.sh`](./simulate-failover.sh) interacts with k8s to simulate a successful vs unsuccessful
failover.

## Happy Path Works

Run this, and verify it exits with `0` and printed the values 1 through 10 (indicating data was replicated and node-1
promoted).

```shell
./simulate-failover.sh
```

## But it's not resilient

Run this, which does the same thing _--except it restarts node-1 before promoting it --_ and watch it fail because
node-1 refuses to start up if it can't find the primary (node-0).

```shell
./simulate-failover.sh restart
```

# Commands

For reference, these are the commands used in the script.

| Purpose                            | Command                                                                                                                      |
|------------------------------------|------------------------------------------------------------------------------------------------------------------------------|
| Delete Cluster                     | `kubectl delete namespace failover-issue`                                                                                    |
| Deploy Cluster                     | `kubectl apply -k failover-issue`                                                                                            |
| Cluster Health                     | `/opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf cluster show --compact` |
| Check app data                     | `PGPASSWORD=pwd psql -U appuser -d appdb --command "SELECT * FROM foo;"`                                                     |
| Emulate disaster                   | `kubectl scale --replicas=0 deployments/postgres-node-0 -n failover-issue`                                                   |
| Restart survivor (reproduce issue) | `kubectl rollout restart deployment postgres-node-1 -n failover-issue`                                                       |
| 🐞 Promote survivor                | `/opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf standby promote`        |

The `deploy cluster` and `promote survivor` both fail because of the restart -- psql isn't available
![image](https://user-images.githubusercontent.com/3299155/173885649-90b5cd96-b8af-4a38-a87f-262789b20784.png)
