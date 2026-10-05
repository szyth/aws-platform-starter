data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = "${var.project}-dev"
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "vpc" {
  source = "../../modules/vpc"

  name               = local.name
  cidr               = var.vpc_cidr
  azs                = local.azs
  single_nat_gateway = var.single_nat_gateway
}

module "eks" {
  source = "../../modules/eks"

  cluster_name        = "${local.name}-eks"
  cluster_version     = var.cluster_version
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_access_cidrs = var.public_access_cidrs
  node_instance_types = var.node_instance_types
}

module "github_oidc" {
  source = "../../modules/github-oidc"

  state_bucket_name = var.state_bucket_name
  allowed_subjects = [
    "repo:${var.github_repo}:pull_request",
    "repo:${var.github_repo}:ref:refs/heads/main",
  ]
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name          = "rust-backend-starter"
  github_oidc_provider_arn = module.github_oidc.provider_arn
  # only merges to main may publish images; PRs build but don't push
  push_subjects = ["repo:${var.app_github_repo}:ref:refs/heads/main"]
}

module "rds" {
  source = "../../modules/rds"

  name                    = "${local.name}-db"
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  allowed_security_groups = { eks_nodes = module.eks.node_security_group_id }
  db_name                 = "app"
}
