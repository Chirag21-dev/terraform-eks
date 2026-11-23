resource "aws_vpc" "devopsshack_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "devopsshack-vpc"
  }
}

resource "aws_subnet" "devopsshack_subnet" {
  count=2
  vpc_id                  = aws_vpc.devopsshack_vpc.id
  
  cidr_block              = cidrsubnet(aws_vpc.devopsshack_vpc.cidr_block, 8,count.index)
  
  availability_zone= element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    
    Name = "devopsshack-subnet"
  }
}

resource "aws_internet_gateway" "devopsshack_igw" {
  vpc_id = aws_vpc.devopsshack_vpc.id

  tags = {
    Name = "devopsshack-igw"
  }
}

resource "aws_route_table" "devopsshack_route_table" {
  vpc_id = aws_vpc.devopsshack_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devopsshack_igw.id
  }

   tags = {
    Name = "devopsshack-route-table"
  }
}

resource "aws_route_table_association" "devopsshack_association" {
  count          = length(aws_subnet.devopsshack_subnet)
  subnet_id      = aws_subnet.devopsshack_subnet[count.index].id
  
  route_table_id = aws_route_table.devopsshack_route_table.id
}

resource "aws_security_group" "devopsshack_cluster_sg" {
  vpc_id = aws_vpc.devopsshack_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devopsshack-cluster-sg"
  }
}

resource "aws_security_group" "devopsshack_node_sg" {
  vpc_id = aws_vpc.devopsshack_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devopsshack-node-sg"
  }
}

resource "aws_eks_cluster" "automode" {
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.eks_cluster_role.arn

  # EKS Auto Mode requires these bootstrap settings
  bootstrap_self_managed_addons = false

  vpc_config {
    subnet_ids = aws_subnet.devopsshack_subnet[*].id
    security_group_ids = [aws_security_group.devopsshack_cluster_sg.id]
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
