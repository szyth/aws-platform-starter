terraform {
  required_version = ">= 1.10" # 1.10+ supports native S3 state locking (use_lockfile)

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend blocks can't use variables, so the values are passed at init time:
  #   terraform init -backend-config=backend.hcl
  backend "s3" {}
}
