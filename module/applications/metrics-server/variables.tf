variable "eks_cluster_endpoint" {}
variable "eks_cluster_ca" {}
variable "eks_cluster_token" {}
variable "namespace" {
  default = "kube-system"
}
variable "chart" {}
variable "repository" {}
variable "version" {}
variable "values_file" {}
