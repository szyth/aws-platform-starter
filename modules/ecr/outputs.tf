output "repository_url" {
  description = "Registry/repository to tag and push images to."
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  value = aws_ecr_repository.this.arn
}

output "push_role_arn" {
  description = "Role the service's CI assumes to push images."
  value       = aws_iam_role.push.arn
}
