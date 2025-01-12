
provider "helm" {
  kubernetes {
    host                   = var.eks_cluster_endpoint
    cluster_ca_certificate = var.eks_cluster_ca
    token                  = var.eks_cluster_token
  }
}

resource "helm_release" "application" {
  name       = "metrics-server"
  namespace  = var.namespace
  repository = var.repository
  chart      = var.chart
  version    = var.version
  values     = [file(var.values_file)]
}