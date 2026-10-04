# -----------------------------------------------------------------------------
# EKS module: a thin wrapper around the community module so you aren't writing
# ~40 low-level resources by hand. In the interview, be ready to say what the
# module creates for you: control plane, cluster + node IAM roles, security
# groups, managed node group, OIDC provider (for IRSA), and add-ons.
# -----------------------------------------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids # nodes live in PRIVATE subnets

  # API endpoint reachable from the internet but restricted to your CIDRs.
  # Production alternative: private endpoint only + VPN/bastion.
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = var.public_access_cidrs

  # Gives the identity that runs Terraform admin rights in the cluster
  # (uses EKS access entries, the modern replacement for the aws-auth ConfigMap).
  enable_cluster_creator_admin_permissions = true

  # Creates the IAM OIDC provider so pods can assume IAM roles (IRSA).
  enable_irsa = true

  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = {}
    eks-pod-identity-agent = {} # newer, simpler alternative to IRSA
  }

  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }
}
