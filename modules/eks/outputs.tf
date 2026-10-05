output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  description = "Use this when writing IRSA trust policies."
  value       = module.eks.oidc_provider_arn
}

output "node_security_group_id" {
  description = "Security group on the worker nodes (and so on pods). Allow it in DB security groups."
  value       = module.eks.node_security_group_id
}

output "cluster_arn" {
  value = module.eks.cluster_arn
}
