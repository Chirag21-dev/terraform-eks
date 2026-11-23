variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS Auto Mode cluster name"
  type        = string
  default     = "devops-automode-cluster"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version supported in the selected region"
  type        = string
}

#variable "vpc_id" {
  #description = "Existing VPC ID"
  #type        = string
#}

#variable "subnet_ids" {
  #description = "Subnets across at least two Availability Zones"
  #type        = list(string)
#}
