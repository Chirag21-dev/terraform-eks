data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.devopsshack.name
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.devopsshack.name
}
