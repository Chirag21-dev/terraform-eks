module "vpc" {
  source = "./modules/vpc"

  name     = var.cluster_name
  vpc_cidr = var.vpc_cidr
}

module "vpc_endpoints" {
  source = "./modules/vpc-endpoint"

  vpc_id                  = module.vpc.vpc_id
  vpc_cidr                = var.vpc_cidr
  region                  = var.region
  private_subnet_ids      = module.vpc.private_subnets
  private_route_table_ids = module.vpc.private_route_table_ids
}

module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id         = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets

  //depends_on = [
   // module.vpc_endpoints
  //]
}
