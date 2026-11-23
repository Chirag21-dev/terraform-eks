resource "aws_eks_cluster" "automode" {
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.eks_cluster_role.arn

  # EKS Auto Mode requires these bootstrap settings
  bootstrap_self_managed_addons = false

  vpc_config {
    subnet_ids = var.subnet_ids

    endpoint_private_access = true
    endpoint_public_access  = true
  }

  # Enable EKS Auto Mode compute
  compute_config {
    enabled = true

    node_pools = [
      "general-purpose",
      "system"
    ]

    node_role_arn = aws_iam_role.eks_node_role.arn
  }

  # Enable EKS Auto Mode load balancing
  kubernetes_network_config {
    elastic_load_balancing {
      enabled = true
    }
  }

  # Enable EKS Auto Mode block storage
  storage_config {
    block_storage {
      enabled = true
    }
  }

  # Cluster access using EKS API
  access_config {
    authentication_mode = "API"
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policies,
    aws_iam_role_policy_attachment.node_policies
  ]

  tags = {
    Environment = "dev"
    Project     = "EKS-Auto-Mode"
    ManagedBy   = "Terraform"
  }
}
