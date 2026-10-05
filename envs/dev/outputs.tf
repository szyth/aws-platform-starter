output "vpc_id" {
  value = module.vpc.vpc_id
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "github_actions_role_arn" {
  value = module.github_oidc.role_arn
}

output "kubeconfig_command" {
  description = "Run this to point kubectl at the cluster."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "app_ci_push_role_arn" {
  description = "Put this in the app repo's GitHub variable AWS_ROLE_ARN."
  value       = module.ecr.push_role_arn
}

output "db_endpoint" {
  value = module.rds.endpoint
}

output "db_master_secret_arn" {
  description = "aws secretsmanager get-secret-value --secret-id <this> to read the generated password."
  value       = module.rds.master_secret_arn
}

output "db_name" {
  value = module.rds.db_name
}
