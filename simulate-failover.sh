#!/bin/bash

PURPLE='\033[0;35m'
CLEAR='\033[0m'

RESTART=$1

echo -e "${PURPLE}Recreate 'failover-issue' k8s cluster${CLEAR}"
kubectl delete namespace failover-issue
sleep 10
kubectl apply -k failover-issue
sleep 30 

echo -e "${PURPLE}PLEASE VERIFY: node-0 should be primary in the printout${CLEAR}"
node0=$(kubectl get pods -n failover-issue | grep postgres-node-0 | awk '{print $1;}')
kubectl exec -it $node0 -n failover-issue -- /bin/bash -c "/opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf cluster show --compact"

echo -e "${PURPLE}Simulate an issue with node-0 (primary)${CLEAR}"
kubectl scale --replicas=0 deployments/postgres-node-0 -n failover-issue
sleep 5

if [ -n "$RESTART" ]; then
  echo -e "${PURPLE}Restart node-1 (standby)${CLEAR}"
  kubectl rollout restart deployments postgres-node-1 -n failover-issue
  sleep 5
fi

echo -e "${PURPLE}Promote node-1 (will fail if we restarted it)${CLEAR}"
node1=$(kubectl get pods -n failover-issue | grep postgres-node-1 | awk '{print $1;}')
kubectl exec -it $node1 -n failover-issue -- /bin/bash -c "/opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf standby promote"
sleep 5

echo -e "${PURPLE}PLEASE VERIFY: node-1 should be primary in the printout${CLEAR}"
# node-1 should be primary in the printout
kubectl exec -it $node1 -n failover-issue -- /bin/bash -c "/opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh repmgr -f /opt/bitnami/repmgr/conf/repmgr.conf cluster show --compact"

echo -e "${PURPLE}PLEASE VERIFY: should see the values 1 through 10, which were inserted by node-0's initdb.sh script${CLEAR}"
kubectl exec -it postgres-client -n failover-issue -- /bin/bash -c "PGPASSWORD=pwd psql -h postgres-node-1 -U appuser -d appdb --command 'SELECT * FROM foo;'"

echo -e "${PURPLE}DONE.${CLEAR}"
