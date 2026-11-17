module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.26.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  # Private Kubernetes API only
  endpoint_private_access = true
  endpoint_public_access  = false

  # Give the Terraform identity cluster administrator access
  enable_cluster_creator_admin_permissions = true

  # Enable IAM Roles for Service Accounts
  enable_irsa = true

  # Control-plane logging
  enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # EKS managed add-ons
  addons = {
    vpc-cni = {
      most_recent   = true
      before_compute = true
    }

    kube-proxy = {
      most_recent = true
    }

    coredns = {
      most_recent = true
    }

    eks-pod-identity-agent = {
      most_recent   = true
      before_compute = true
    }
  }

  # Private EC2 managed node group
  eks_managed_node_groups = {
    private-workers = {
      name = "private-worker-nodes"

      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      min_size     = 2
      max_size     = 4
      desired_size = 2

      labels = {
        Environment = "production"
        NodeType    = "private"
      }
    }
  }

  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}
