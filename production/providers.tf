provider "aws" {
  region = var.region
}

/*terraform {
    backend "s3" {}
    required_version = ">= 1.0"
    required_providers {
        aws = {

            source = "hashicorp/aws"
            version = "~> 5.49"
        }     
    } 
}*/


provider "helm" {
  kubernetes {

    host                   = var.eks_cluster_endpoint
    cluster_ca_certificate = var.eks_cluster_ca
    token                  = var.eks_cluster_token

  }
}
