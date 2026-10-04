variable "role_name" {
  type    = string
  default = "github-actions-terraform-plan"
}

variable "allowed_subjects" {
  description = <<-EOT
    GitHub OIDC "sub" claims allowed to assume the role, e.g.
    ["repo:my-user/aws-platform-starter:pull_request",
     "repo:my-user/aws-platform-starter:ref:refs/heads/main"]
  EOT
  type        = list(string)
}

variable "state_bucket_name" {
  description = "Name of the Terraform state bucket (from the bootstrap stack)."
  type        = string
}
