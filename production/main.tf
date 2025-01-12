locals {
  projectName = var.project_name
  clusterName = var.cluster_name
}

/*data "aws_eks_cluster" "eks" {
  name = module.eks.eks_cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.eks_cluster_name
}*/

////////////////////////////////////////////////////////////////////////////////////////////////

module "vpc-1" {
  source              = "../module/vpc/"
  vpc_cidr_block      = "10.0.0.0/16"
  dns_hostnames_stateus = true
  dns_support_stateus   = true

  project_name = local.projectName
  eks_name     = local.clusterName
  cluster_type = "shared"

  private_subnets = [
    { cidr = "10.0.1.0/24", az = "us-east-1a" },
    { cidr = "10.0.2.0/24", az = "us-east-1b" }
  ]

  public_subnets = [
    { cidr = "10.0.3.0/24", az = "us-east-1a" },
    { cidr = "10.0.4.0/24", az = "us-east-1b" }
  ]

  create_nat_gateway = true
}

////////////////////////////////////////////////////////////////////////////////////////////////

module "eks" {
  source                 = "../module/eks/"
  project_name           = local.projectName
  eks_name               = local.clusterName
  eks_version            = "1.28" # Adjust to a valid version (1.31 is not supported)
  private_subnets        = module.vpc-1.private_subnet_ids
  public_subnets         = module.vpc-1.public_subnet_ids
  instance_types         = ["t2.medium"]
  desired_size           = 1
  max_size               = 10
  min_size               = 1
  endpoint_private_access = false
  endpoint_public_access  = true
  region                 = var.region
  vpc_id                 = module.vpc-1.vpc_id
}



////////////////////////////////////////////////////////////////////////////////////////////////

module "metrics_server" {
  source                = "../module/applications/metrics"   
  namespace             = "kube-system"
  chart                 = "metrics-server"
  repository            = "https://kubernetes-sigs.github.io/metrics-server/"
  chart_version               = "3.12.1"
  values_file           = "../module/values/metrics-server.yaml"
  eks_dependency        =  module.eks.eks_node_group_dependency

}

////////////////////////////////////////////////////////////////////////////////////////////////

module "autoscaler" {
  source                     = "../module/applications/autoscaler"
  cluster_name               = module.eks.eks_cluster_name
  region                     = var.region
  namespace                  = "kube-system"
  service_account_name       = "cluster-autoscaler"
  policy_file_path           = "../module/policies/policy-autoscaler.json"
  assume_role_policy_file_path = "../module/policies/podrole-autoscaler.json"
}


////////////////////////////////////////////////////////////////////////////////////////////////

module "aws_alb" {
  source                = "../module/applications/alb"   
  cluster_name          = module.eks.eks_cluster_name
  vpc_id                = module.vpc-1.vpc_id
  region                = var.region
  namespace             = "kube-system"
  service_account_name   = "aws-load-balancer-controller"
  repository            = "https://aws.github.io/eks-charts"
  chart                 = "aws-load-balancer-controller"
  chart_version         = "1.7.2"
  policy_file_path           = "../module/policies/policy-autoscaler.json"
  assume_role_policy_file_path = "../module/policies/podrole-autoscaler.json"
  eks_dependency        =  [module.autoscaler.helm_release_name,  module.eks.eks_cluster_name]

}


module "elk_stack" {
  source                    = "../module/applications/elk"

  namespace                 = "elk-stack"
  elasticsearch_chart_version = "8.10.1"
  logstash_chart_version    = "8.10.1"
  filebeat_chart_version    = "8.10.1"
  kibana_chart_version      = "8.10.1"

  elasticsearchvalues_file  = "../module/applications/elk/values/elasticsearchvalues.yaml"
  logstashvalues_file       = "../module/applications/elk/values/logstashvalues.yaml"
  filebeatvalues_file       = "../module/applications/elk/values/filebeatvalues.yaml"
  kibanavalues_file         = "../module/applications/elk/values/kibanavalues.yaml"

  eks_dependency        =  module.eks.eks_node_group_dependency
}
