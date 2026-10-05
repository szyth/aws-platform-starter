variable "repository_name" {
  description = "ECR repository name, usually the service name."
  type        = string
}

variable "image_retention_count" {
  description = "How many images to keep; older ones are expired by a lifecycle rule."
  type        = number
  default     = 10
}

variable "force_delete" {
  description = "Allow destroy even when images exist. true for dev, false for prod."
  type        = bool
  default     = true
}

variable "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider (from the github-oidc module)."
  type        = string
}

variable "push_subjects" {
  description = <<-EOT
    GitHub OIDC "sub" claims allowed to push images, e.g.
    ["repo:my-user/my-service:ref:refs/heads/main"]
  EOT
  type        = list(string)
}
