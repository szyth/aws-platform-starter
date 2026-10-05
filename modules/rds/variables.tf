variable "name" {
  description = "Identifier prefix for the instance and its related resources."
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  description = "Subnets for the DB subnet group (private, at least 2 AZs)."
  type        = list(string)
}

variable "allowed_security_groups" {
  description = <<-EOT
    Security groups allowed to connect on 5432, keyed by a static label, e.g.
    { eks_nodes = module.eks.node_security_group_id }. The keys must be known at
    plan time (for_each), the IDs may be created in the same apply.
  EOT
  type        = map(string)
}

variable "db_name" {
  type    = string
  default = "app"
}

variable "username" {
  type    = string
  default = "app"
}

variable "engine_version" {
  description = "Postgres major version; same as local docker compose."
  type        = string
  default     = "17"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "GiB of gp3 storage."
  type        = number
  default     = 20
}

variable "multi_az" {
  description = "Standby replica in a second AZ with automatic failover. Doubles cost; true for prod."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Automated backups / point-in-time restore window. 0 disables backups."
  type        = number
  default     = 1
}

variable "deletion_protection" {
  description = "false for a dev sandbox you destroy nightly; true for prod."
  type        = bool
  default     = false
}
