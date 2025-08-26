#!/bin/bash

# Record start time
START=$(date +%s)

# Rollback to the desired revision 
REVISION=1
echo "Rolling back nginx-app to revision $REVISION..."
helm rollback nginx-app $REVISION -n stateless

echo "Waiting for pod to recover..."

# Wait until at least one pod is ready and running
while true; do
  POD=$(kubectl get pods -n stateless -l app=nginx-app -o jsonpath='{.items[0].metadata.name}')
  
  READY=$(kubectl get pod "$POD" -n stateless -o jsonpath='{.status.containerStatuses[0].ready}')
  PHASE=$(kubectl get pod "$POD" -n stateless -o jsonpath='{.status.phase}')
  
  if [[ "$READY" == "true" && "$PHASE" == "Running" ]]; then
    break
  fi

  sleep 1
done

# Record end time
END=$(date +%s)

# Print total rollback time
echo "Rollback took $((END - START)) seconds"
