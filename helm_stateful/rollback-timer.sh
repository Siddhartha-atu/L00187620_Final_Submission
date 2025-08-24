#!/bin/bash

# Configuration
RELEASE="my-mysql"
NAMESPACE="stateful"
REVISION=1               # working revision
POD_LABEL="app=mysql-app" # label selector for StatefulSet pod

START=$(date +%s)

echo "Triggering Helm rollback to revision $REVISION..."
helm rollback $RELEASE $REVISION -n $NAMESPACE

# Delete old pod to force recreation
OLD_POD=$(kubectl get pods -n $NAMESPACE -l $POD_LABEL -o jsonpath='{.items[0].metadata.name}')
echo "Deleting old pod $OLD_POD to force restart..."
kubectl delete pod $OLD_POD -n $NAMESPACE

# Wait for pod to recover
echo "Waiting for pod to become Running and Ready..."
TIMEOUT=300  # max 5 minutes
ELAPSED=0
while true; do
  POD=$(kubectl get pods -n $NAMESPACE -l $POD_LABEL -o jsonpath='{.items[0].metadata.name}')
  READY=$(kubectl get pod "$POD" -n $NAMESPACE -o jsonpath='{.status.containerStatuses[0].ready}')
  PHASE=$(kubectl get pod "$POD" -n $NAMESPACE -o jsonpath='{.status.phase}')

  if [[ "$READY" == "true" && "$PHASE" == "Running" ]]; then
    break
  fi

  sleep 1
  ELAPSED=$((ELAPSED + 1))
  if [[ $ELAPSED -ge $TIMEOUT ]]; then
    echo "Timeout waiting for pod recovery!"
    exit 1
  fi
done

END=$(date +%s)
echo "Rollback took $((END - START)) seconds"

# Optional: login to MySQL to verify
echo "Verifying MySQL data..."
winpty kubectl exec -it $POD -c mysql -n $NAMESPACE -- mysql -u root -p
