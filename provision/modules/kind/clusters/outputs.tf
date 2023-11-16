output "kubeconfig" {
  value=kind_cluster.default.kubeconfig
  description = "kube config files"
}