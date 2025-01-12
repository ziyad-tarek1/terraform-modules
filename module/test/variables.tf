

variable "namespace" {
  default = "kube-system"
}
variable "chart" {}
variable "repository" {}
variable "chart_version" {}
variable "values_file" {}

variable "eks_dependency" {
  
}