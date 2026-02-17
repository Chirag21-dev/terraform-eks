
resource "random_id" "suffix" {
  byte_length = 4
}
resource "random_string" "suffix" {
  length  = 6
  special = false
}

resource "aws_vpc" "devopsshack_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "devopsshack-vpc"
  }
}

resource "aws_subnet" "devopsshack_subnet" {
  
  vpc_id                  = aws_vpc.devopsshack_vpc.id
  
  cidr_block              = cidrsubnet(aws_vpc.devopsshack_vpc.cidr_block, 8,0)
  
  availability_zone= "us-east-1a"
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
  
  subnet_id      = aws_subnet.devopsshack_subnet.id
  
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

resource "aws_eks_cluster" "devopsshack" {
  name     = "devopsshack-cluster"
  role_arn = aws_iam_role.devopsshack_cluster_role.arn

  vpc_config {
    subnet_ids         = [aws_subnet.devopsshack_subnet.id]
    security_group_ids = [aws_security_group.devopsshack_cluster_sg.id]
  }
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name    = aws_eks_cluster.devopsshack.name
  addon_name      = "aws-ebs-csi-driver"
  addon_version            = "v1.30.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

#for cloudwatch monitoring of eks
#resource "aws_eks_addon" "cloudwatch_observability" {
#  cluster_name = aws_eks_cluster.devopsshack.name
#  addon_name   = "amazon-cloudwatch-observability"
#
#  resolve_conflicts_on_create = "OVERWRITE"
#  resolve_conflicts_on_update = "OVERWRITE"
#}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "k8s_keypair" {
  key_name   = "K8s keypair-${random_string.suffix.result}"
  public_key = tls_private_key.example.public_key_openssh
}


resource "aws_eks_node_group" "devopsshack" {
  cluster_name    = aws_eks_cluster.devopsshack.name
  node_group_name = "devopsshack-node-group"
  node_role_arn   = aws_iam_role.devopsshack_node_group_role.arn
  subnet_ids      = [aws_subnet.devopsshack_subnet.id]
  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  instance_types = ["t2.small"]

  remote_access {
    ec2_ssh_key = aws_key_pair.k8s_keypair.key_name
    source_security_group_ids = [aws_security_group.devopsshack_node_sg.id]
  }
}

resource "aws_iam_role" "devopsshack_cluster_role" {
  name = "devopsshack-cluster-role-${random_id.suffix.hex}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "devopsshack_cluster_role_policy" {
  role       = aws_iam_role.devopsshack_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_openid_connect_provider" "oidc" {
  url = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0ecd2e9d8"]
}

#For ebs volume role : 
resource "aws_iam_role" "ebs_csi_driver" {
  name = "AmazonEKS_EBS_CSI_DriverRole"
  assume_role_policy = jsonencode({

"Version": "2012-10-17",
"Statement": [
{
"Effect": "Allow",
"Principal": {
Federated = aws_iam_openid_connect_provider.oidc.arn
},
"Action": "sts:AssumeRoleWithWebIdentity",
"Condition": {
"StringEquals": {
"${replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub" :"system:serviceaccount:kube-system:ebs-csi-controller-sa"
 }
}
}
]
})
}

# For ebs volume policy: 
resource "aws_iam_role_policy_attachment" "ebs_csi_driver_attach" {
role       = aws_iam_role.ebs_csi_driver.name
policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_role" "devopsshack_node_group_role" {
  name = "devopsshack-node-group-role-${random_id.suffix.hex}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "devopsshack_node_group_role_policy" {
  role       = aws_iam_role.devopsshack_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "devopsshack_node_group_cni_policy" {
  role       = aws_iam_role.devopsshack_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "worker_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.devopsshack_node_group_role.name
}

/*resource "aws_iam_role_policy_attachment" "devopsshack_node_group_cloudwatch_policy" {
  role       = aws_iam_role.devopsshack_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}*/


provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

resource "aws_iam_role" "aws_lb_controller" {
  name = "AmazonEKSLoadBalancerControllerRole-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.oidc.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "aws_lb_controller_attach" {
  role       = aws_iam_role.aws_lb_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLoadBalancerControllerIAMPolicy"
}

resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.devopsshack.name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
}

resource "kubernetes_service_account" "aws_lb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_lb_controller.arn
    }
  }
}
