variable "region" {
  type    = string
  default = "ap-south-1" # change if you prefer another region
}

variable "project" {
  type    = string
  default = "platform-starter"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "single_nat_gateway" {
  description = "Keep true to save money while learning; set false to demo a per-AZ HA design."
  type        = bool
  default     = true
}

variable "cluster_version" {
  type    = string
  default = "1.34"
}

variable "node_instance_types" {
  description = "EKS worker instance types. New AWS accounts on the Free plan only allow free-tier eligible types (e.g. c7i-flex.large, not t3.medium)."
  type        = list(string)
  default     = ["c7i-flex.large"]
}

variable "public_access_cidrs" {
  description = "Who may reach the EKS API endpoint. Set to [\"<your-ip>/32\"]."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "github_repo" {
  description = "GitHub repo allowed to assume the CI role, in owner/name form."
  type        = string
}

variable "state_bucket_name" {
  description = "State bucket created by the bootstrap stack."
  type        = string
}

variable "app_github_repo" {
  description = "Application repo whose CI may push images to ECR, in owner/name form."
  type        = string
}

variable "github_owner_id" {
  description = "Numeric ID of the GitHub owner (user/org); GitHub OIDC sub claims include it."
  type        = string
}
