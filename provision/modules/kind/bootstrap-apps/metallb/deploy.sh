#!/bin/sh

MANIFEST_PATH=$1
MANIFEST_NAMESPACE=$2

# Deploy metal LB resources
kubectl apply -f $MANIFEST_PATH

# query for get DaemonSets that should be installed on node from Metal LB resources
metalLbDesiredPod=$(kubectl get ds -n $MANIFEST_NAMESPACE -o=jsonpath-as-json='{.items[*].status}')
totalSpeaker=$(jq -r '.[].desiredNumberScheduled' <<< $metalLbDesiredPod)

# Must +1 because there is controller for metallb pod deployment
totalSpeaker=$((totalSpeaker+1))

# Check state of Metal LB resources are ready
while true
do

  total=0
  for state in $(jq -r '.[]' <<< $(kubectl get pods -o=jsonpath-as-json='{.items[*].status.phase}' -n $MANIFEST_NAMESPACE));do
    if [ $state = Running ]
    then
      total=$((total+1))
    else
      echo "$state"
    fi
  done

  echo "Currently Running for $total pods, it needs to be $totalSpeaker pods in running state"
  if [[ $total -ge  $totalSpeaker ]]
  then
    break
  fi
  sleep 10
  echo "Preparing the Metal LB Pod ..."
done

# Get Subnet of Kind Cluster
# It's needed for create ip subnet for Service
svcSubnet=$(jq -r '.[0].Subnet' <<< $(docker network inspect -f '{{json .IPAM.Config}}' kind))
metallbPod="192.168.1.1/24"

if [ svcSubnet != "" ]
then
  length=${#svcSubnet}
  metallbPod="${svcSubnet: 0: length-6}100.0/24"
fi

# Apply the configuration
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: $MANIFEST_NAMESPACE
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - $metallbPod
EOF