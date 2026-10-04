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
