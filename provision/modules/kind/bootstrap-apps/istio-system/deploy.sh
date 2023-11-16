MANIFEST_PATH=$1
MANIFEST_NAMESPACE=$2

istioctl install --set profile=demo -y && kubectl apply -f $MANIFEST_PATH -n $MANIFEST_NAMESPACE