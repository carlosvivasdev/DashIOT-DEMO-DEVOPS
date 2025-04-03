output "kubeconfig" {
  value = digitalocean_kubernetes_cluster.default_cluster.kube_config[0].raw_config
  sensitive = true
}