provider "aws" {
  region = "us-east-1"
}

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
  //count = 2
  //count=1
  vpc_id                  = aws_vpc.devopsshack_vpc.id
  #cidr_block              = cidrsubnet(aws_vpc.devopsshack_vpc.cidr_block, 8, count.index)
  cidr_block              = cidrsubnet(aws_vpc.devopsshack_vpc.cidr_block, 8,0)
  //availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)
  availability_zone= "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    #Name = "devopsshack-subnet-${count.index}"
    Name = "devopsshack-subnet
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
  #count          = 2
  #subnet_id      = aws_subnet.devopsshack_subnet[count.index].id
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
    subnet_ids         = aws_subnet.devopsshack_subnet[*].id
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
  subnet_ids      = aws_subnet.devopsshack_subnet[*].id
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

//resource "aws_iam_role_policy_attachment" "ebs_csi_driver_attach" {
//  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
//  role       = aws_iam_role.devopsshack_cluster_role.name
//}

/*For ebs volume role : resource "aws_iam_role" "ebs_csi_driver" {
  name = "AmazonEKS_EBS_CSI_DriverRole"
  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
{
"Effect": "Allow",
"Principal": {
"Federated": "arn:aws:iam::231726701699:oidc-provider/https://oidc.eks.us-east-1.amazonaws.com/id/CBCD46860448EDB4151BC3071196F054"
},
"Action": "sts:AssumeRoleWithWebIdentity",
"Condition": {
"StringEquals": {
"https://oidc.eks.us-east-1.amazonaws.com/id/CBCD46860448EDB4151BC3071196F054:sub":"system:serviceaccount:kube-system:ebs-csi-controller-sa"
}
}
}
]
}
EOF
}

# For ebs volume policy: resource "aws_iam_role_policy_attachment" "ebs_csi_driver_attach" {
role       = aws_iam_role.ebs_csi_driver.name
policy_arn = "arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicy"
}*/

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
