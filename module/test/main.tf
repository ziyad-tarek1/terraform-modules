
resource "helm_release" "application" {
  name       = "metrics-server"
  namespace  = var.namespace
  repository = var.repository
  chart      = var.chart
  version    = var.chart_version
  values     = [file(var.values_file)]
 depends_on = [var.eks_dependency]

}


