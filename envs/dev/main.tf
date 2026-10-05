data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = "${var.project}-dev"

  # GitHub OIDC "sub" claims now embed immutable IDs:
  #   repo:<owner>@<owner_id>/<repo>@<repo_id>:<context>
  # (seen in CloudTrail on a rejected AssumeRoleWithWebIdentity). Trust that format with the
  # owner ID pinned, plus the older name-only format.
  gh_owner         = split("/", var.github_repo)[0]
  platform_repo    = split("/", var.github_repo)[1]
  app_repo         = split("/", var.app_github_repo)[1]
  platform_sub_ids = "repo:${local.gh_owner}@${var.github_owner_id}/${local.platform_repo}@*"
  app_sub_ids      = "repo:${local.gh_owner}@${var.github_owner_id}/${local.app_repo}@*"
  azs              = slice(data.aws_availability_zones.available.names, 0, 2)
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
    "${local.platform_sub_ids}:pull_request",
    "${local.platform_sub_ids}:ref:refs/heads/main",
    "repo:${var.github_repo}:pull_request",
    "repo:${var.github_repo}:ref:refs/heads/main",
  ]
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name          = "rust-backend-starter"
  github_oidc_provider_arn = module.github_oidc.provider_arn
  # only merges to main may publish images; PRs build but don't push
  push_subjects = [
    "${local.app_sub_ids}:ref:refs/heads/main",
    "repo:${var.app_github_repo}:ref:refs/heads/main",
  ]
}

module "rds" {
  source = "../../modules/rds"

  name                    = "${local.name}-db"
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  allowed_security_groups = { eks_nodes = module.eks.node_security_group_id }
  db_name                 = "app"
}

# ---- Continuous deployment: let the app repo's CI role deploy into the cluster ----
# AWS side: find the cluster (update-kubeconfig needs DescribeCluster).
data "aws_iam_policy_document" "app_ci_eks" {
  statement {
    actions   = ["eks:DescribeCluster"]
    resources = [module.eks.cluster_arn]
  }
}

resource "aws_iam_role_policy" "app_ci_eks" {
  name   = "eks-describe"
  role   = split("/", module.ecr.push_role_arn)[1]
  policy = data.aws_iam_policy_document.app_ci_eks.json
}

# Kubernetes side: an EKS access entry maps the IAM role into the cluster with
# "edit" rights in the default namespace only (enough for helm upgrade).
resource "aws_eks_access_entry" "app_ci" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.ecr.push_role_arn
}

resource "aws_eks_access_policy_association" "app_ci" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.ecr.push_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type       = "namespace"
    namespaces = ["default"]
  }

  depends_on = [aws_eks_access_entry.app_ci]
}
