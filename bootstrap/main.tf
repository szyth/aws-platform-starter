# -----------------------------------------------------------------------------
# BOOTSTRAP: creates the S3 bucket that holds remote Terraform state.
#
# Chicken-and-egg: the state bucket can't store its own state before it exists,
# so this tiny stack uses LOCAL state. Apply it once, then never touch it again.
# (Good interview talking point: "how do you bootstrap remote state?")
# -----------------------------------------------------------------------------
terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "region" {
  type    = string
  default = "ap-south-1"
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

locals {
  # Account ID in the name keeps it globally unique without guessing.
  bucket_name = "tfstate-${data.aws_caller_identity.current.account_id}-${var.region}"
}

resource "aws_s3_bucket" "state" {
  bucket = local.bucket_name
}

# Versioning = you can recover from a corrupted or accidentally overwritten state.
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# State can contain secrets, so encrypt at rest.
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# State must never be public.
resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "state_bucket" {
  value = aws_s3_bucket.state.id
}
