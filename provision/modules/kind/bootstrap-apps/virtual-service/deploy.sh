MANIFEST_PATH=$1
MANIFEST_NAMESPACE=$2

kubectl apply -f $MANIFEST_PATH -n $MANIFEST_NAMESPACE