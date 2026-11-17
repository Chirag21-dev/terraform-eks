resource "aws_security_group" "endpoint_sg" {
  name        = "private-eks-endpoint-sg"
  description = "HTTPS access from private EKS VPC"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from private VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-eks-endpoint-sg"
  }
}

# Interface endpoints
resource "aws_vpc_endpoint" "interface" {
  for_each = var.interface_services

  vpc_id = var.vpc_id

  service_name = "com.amazonaws.${var.region}.${each.value}"

  vpc_endpoint_type = "Interface"

  subnet_ids = var.private_subnet_ids

  security_group_ids = [
    aws_security_group.endpoint_sg.id
  ]

  private_dns_enabled = true

  tags = {
    Name = "${each.value}-endpoint"
  }
}

# S3 Gateway endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id = var.vpc_id

  service_name = "com.amazonaws.${var.region}.s3"

  vpc_endpoint_type = "Gateway"

  route_table_ids = var.private_route_table_ids

  tags = {
    Name = "private-eks-s3-endpoint"
  }
}
