#!/bin/bash

# Configuration
RELEASE="mysql"
NAMESPACE="stateful"
REVISION=1                 # last known working revision
POD_LABEL="app=mysql-mysql" # label selector for StatefulSet pod
TIMEOUT=300                 # wait up to 5 minutes for pod recovery

START=$(date +%s)

echo "Triggering Helm rollback to revision $REVISION..."
helm rollback $RELEASE $REVISION -n $NAMESPACE
if [[ $? -ne 0 ]]; then
  echo "❌ Helm rollback failed!"
  exit 1
fi

# Delete old pod to force recreation
OLD_POD=$(kubectl get pods -n $NAMESPACE -l $POD_LABEL -o jsonpath='{.items[0].metadata.name}')
if [[ -n "$OLD_POD" ]]; then
  echo "Deleting old pod $OLD_POD to force restart..."
  kubectl delete pod "$OLD_POD" -n $NAMESPACE
else
  echo "⚠️ No pod found with label $POD_LABEL"
fi

# Wait for pod to become Running and Ready
echo "Waiting for pod to become Running and Ready..."
ELAPSED=0
while true; do
  POD=$(kubectl get pods -n $NAMESPACE -l $POD_LABEL -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  if [[ -z "$POD" ]]; then
    sleep 1
    ELAPSED=$((ELAPSED + 1))
    if [[ $ELAPSED -ge $TIMEOUT ]]; then
      echo "❌ Timeout waiting for pod to appear!"
      exit 1
    fi
    continue
  fi

  READY=$(kubectl get pod "$POD" -n $NAMESPACE -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)
  PHASE=$(kubectl get pod "$POD" -n $NAMESPACE -o jsonpath='{.status.phase}' 2>/dev/null)

  if [[ "$READY" == "true" && "$PHASE" == "Running" ]]; then
    echo "✅ Pod $POD is Running and Ready"
    break
  fi

  sleep 2
  ELAPSED=$((ELAPSED + 2))
  if [[ $ELAPSED -ge $TIMEOUT ]]; then
    echo "❌ Timeout waiting for pod recovery!"
    exit 1
  fi
done

END=$(date +%s)
echo "Rollback took $((END - START)) seconds"

# Optional: verify MySQL data
# Uncomment and set password if you want verification
# MYSQL_PASS="rootpass"
# kubectl exec -it $POD -c mysql -n $NAMESPACE -- \
#   mysql -u root -p"$MYSQL_PASS" -e "SHOW DATABASES;"
