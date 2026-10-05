# -----------------------------------------------------------------------------
# RDS Postgres in private subnets. Reachable only from the given security groups
# (the EKS nodes), never from the internet. The master password is generated and
# rotated by RDS and stored in Secrets Manager: it never appears in Terraform code.
# -----------------------------------------------------------------------------

resource "aws_db_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.private_subnet_ids
  tags       = { Name = var.name }
}

resource "aws_security_group" "db" {
  name        = "${var.name}-db"
  description = "Postgres access for ${var.name}"
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.name}-db" }
}

# Only the listed security groups (not CIDRs) may reach 5432: if a node is
# replaced its IP changes, but its security group doesn't.
resource "aws_vpc_security_group_ingress_rule" "postgres" {
  for_each = var.allowed_security_groups

  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = each.value
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "Postgres from ${each.key}"
}

resource "aws_db_instance" "this" {
  identifier     = var.name
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.db_name
  username = var.username
  # RDS generates the password and keeps it in Secrets Manager (and can rotate it)
  manage_master_user_password = true

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  backup_retention_period    = var.backup_retention_days
  auto_minor_version_upgrade = true

  # dev sandbox: allow terraform destroy without a final snapshot
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = !var.deletion_protection
  final_snapshot_identifier = var.deletion_protection ? "${var.name}-final" : null
}
