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
