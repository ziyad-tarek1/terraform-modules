locals {
  projectName = var.project_name
  clusterName = var.cluster_name
}

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