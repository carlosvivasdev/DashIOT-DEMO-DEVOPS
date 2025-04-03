# Obtiene la última versión disponible de Kubernetes
data "digitalocean_kubernetes_versions" "latest" {}

# Crea el clúster de Kubernetes
resource "digitalocean_kubernetes_cluster" "default_cluster" {
  name    = var.cluster_name
  region  = var.region
  version = data.digitalocean_kubernetes_versions.latest.latest_version
  tags    = ["k8s-cluster"]
  node_pool {
    name       = "${var.cluster_name}-default-pool"
    size       = var.default_node_size
    node_count = 1
    # auto_scale = true
    # min_nodes  = var.min_nodes
    # max_nodes  = var.max_nodes
  }
}
