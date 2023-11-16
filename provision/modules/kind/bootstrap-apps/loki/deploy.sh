VIRTUAL_SERVICE_PATH=$1

helm repo add loki https://grafana.github.io/loki/charts
helm repo update
helm upgrade --install loki loki/loki-stack -n loki

kubectl apply -f $VIRTUAL_SERVICE_PATH -n istio-system