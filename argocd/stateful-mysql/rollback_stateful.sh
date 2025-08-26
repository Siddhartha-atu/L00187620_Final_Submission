#!/bin/bash

echo " Starting rollback timer..."
START=$(date +%s)

# Identify pod
POD=$(kubectl get pods -n stateful -l app=mysql-app -o jsonpath='{.items[0].metadata.name}')
echo " Deleting pod: $POD"
kubectl delete pod "$POD" -n stateful

echo " Waiting for new pod to become Ready..."

# Wait for new pod to appear and become ready
while true; do
  POD=$(kubectl get pods -n stateful -l app=mysql-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  if [ -n "$POD" ]; then
    READY=$(kubectl get pod "$POD" -n stateful -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)
    PHASE=$(kubectl get pod "$POD" -n stateful -o jsonpath='{.status.phase}' 2>/dev/null)
    if [[ "$READY" == "true" && "$PHASE" == "Running" ]]; then
      break
    fi
  fi
  sleep 1
done

END=$(date +%s)
DURATION=$((END - START))

echo "Pod is back to Running."
echo " Rollback via Argo CD took $DURATION seconds."

