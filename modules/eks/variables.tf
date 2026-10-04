variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  description = "Kubernetes version. Pick one in STANDARD support to avoid extended-support fees (see README)."
  type        = string
  default     = "1.34"
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint. Use your own IP as x.x.x.x/32."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}
