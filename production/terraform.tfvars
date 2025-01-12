region = "us-east-1"

host                   = data.aws_eks_cluster.eks.endpoint
cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
token                  = data.aws_eks_cluster_auth.eks.token

  eks_cluster_endpoint = module.eks.e_cksluster_endpoint
  eks_cluster_ca       = base64decode(module.eks.eks_cluster_ca)
  eks_cluster_token    = module.eks.eks_cluster_auth_token


project_name = "EKS"
cluster_name = "my-eks"