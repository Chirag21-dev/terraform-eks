output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "vpc_interface_endpoints" {
  value = module.vpc_endpoints.interface_endpoint_ids
}

output "s3_gateway_endpoint" {
  value = module.vpc_endpoints.s3_endpoint_id
}
