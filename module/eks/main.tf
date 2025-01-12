
/// EKS IAM Role for Cluster
resource "aws_iam_role" "eks" {
  name               = "${var.project_name}-eks-cluster"
  assume_role_policy = file("${path.module}/policies/eks-policy.json")
}

resource "aws_iam_role_policy_attachment" "eks" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

/// EKS Cluster
resource "aws_eks_cluster" "eks" {
  name     = var.eks_name
  role_arn = aws_iam_role.eks.arn
  version  = var.eks_version

  vpc_config {
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    subnet_ids              = var.private_subnets
  }

  access_config {
    authentication_mode                          = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks]
}

/// Worker IAM Role
resource "aws_iam_role" "worker" {
  name               = "${var.project_name}-eks-worker"
  assume_role_policy = file("${path.module}/policies/ec2-policy.json")
}

/// Autoscaler IAM Policy
resource "aws_iam_policy" "autoscaler" {
  name   = "${var.project_name}-autoscaler-policy"
  policy = file("${path.module}/policies/autoscaler-policy.json")
}

/// Attach Policies to Worker Role
resource "aws_iam_role_policy_attachment" "autoscaler" {
  policy_arn = aws_iam_policy.autoscaler.arn
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.worker.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker.name
}

/// EKS Node Group
resource "aws_eks_node_group" "general" {
  cluster_name    = aws_eks_cluster.eks.name
  version         = var.eks_version
  node_group_name = "${var.eks_name}-general"

  subnet_ids      = var.public_subnets
  capacity_type   = "ON_DEMAND"
  instance_types  = var.instance_types

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "${var.eks_name}-general"
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  node_role_arn = aws_iam_role.worker.arn
}

/// EKS Add-On for Pod Identity Agent
resource "aws_eks_addon" "pod-addon" {
  cluster_name  = aws_eks_cluster.eks.name
  addon_name    = "eks-pod-identity-agent"
  addon_version = "v1.3.4-eksbuild.1"
}

data "aws_eks_cluster" "eks" {
  name = module.eks_cluster.eks_cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks_cluster.eks_cluster_name
}
