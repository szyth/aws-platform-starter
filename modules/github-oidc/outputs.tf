output "role_arn" {
  description = "Put this in the GitHub repo secret AWS_ROLE_ARN."
  value       = aws_iam_role.plan.arn
}

output "provider_arn" {
  description = "GitHub OIDC provider ARN, for other roles that trust GitHub Actions."
  value       = aws_iam_openid_connect_provider.github.arn
}
