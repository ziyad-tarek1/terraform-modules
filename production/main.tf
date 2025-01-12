locals {
  projectName = var.project_name
  clusterName = var.cluster_name
}



////////////////////////////////////////////////////////////////////////////////////////////////

module "vpc-1" {
  source = "../modules/vpc/"
  vpc_cidr_block = "10.0.0.0/16"

  dns_hostnames_stateus = true
  dns_support_stateus   = true

  project_name = local.projectName
  eks_name = local.clusterName
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
  source                 = "../modules/eks/"
  project_name           = local.projectName
  eks_name               = local.clusterName
  eks_version            = "1.31"
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
  source             = "../modules/applications/metrics-server"
  eks_cluster_endpoint = module.eks.eks_cluster_endpoint
  eks_cluster_ca       = base64decode(module.eks.eks_cluster_ca)
  eks_cluster_token    = module.eks.eks_cluster_auth_token
  namespace            = "kube-system"
  chart                = "metrics-server"
  repository           = "https://kubernetes-sigs.github.io/metrics-server/"
  version              = "3.12.1"
  values_file          = "path/to/values/metrics-server.yaml"
}



////////////////////////////////////////////////////////////////////////////////////////////////
module "autoscaler" {
  source                        = "../modules/autoscaler"
  cluster_name                  = module.eks.eks_cluster_name
  region                        = var.region
  namespace                     = "kube-system"
  service_account_name          = "cluster-autoscaler"
  policy_file_path              = "path/to/policy-autoscaler.json"
  assume_role_policy_file_path  = "path/to/podrole-autoscaler.json"
}

