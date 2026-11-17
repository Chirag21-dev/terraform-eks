variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "region" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "private_route_table_ids" {
  type = list(string)
}

variable "interface_services" {
  type = set(string)

  default = [
    "ec2",
    "ecr.api",
    "ecr.dkr",
    "sts",
    "logs",
    "secretsmanager",
    "eks-auth",
    "elasticloadbalancing",
    "autoscaling"
  ]
}
