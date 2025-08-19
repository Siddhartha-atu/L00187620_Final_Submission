#!/bin/bash


START=$(date +%s)

helm rollback nginx 3 -n stateless

echo "Waiting for pod to recover..."
while true; do
  POD=$(kubectl get pods -n stateless -l app=nginx -o jsonpath='{.items[0].metadata.name}')
  READY=$(kubectl get pod "$POD" -n stateless -o jsonpath='{.status.containerStatuses[0].ready}')
  PHASE=$(kubectl get pod "$POD" -n stateless -o jsonpath='{.status.phase}')
  
  if [[ "$READY" == "true" && "$PHASE" == "Running" ]]; then
    break
  fi
  sleep 1
done

END=$(date +%s)
echo "Rollback took $((END - START)) seconds"

