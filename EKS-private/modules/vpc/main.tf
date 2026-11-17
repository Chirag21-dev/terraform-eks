data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3"

  name = "${var.name}-vpc"
  cidr = var.vpc_cidr

  azs = slice(
    data.aws_availability_zones.available.names,
    0,
    3
  )

  # Private subnets only
  private_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]

  public_subnets = []

  # No Internet Gateway or NAT Gateway
  create_igw         = false
  enable_nat_gateway = false

  enable_dns_support   = true
  enable_dns_hostnames = true

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}
