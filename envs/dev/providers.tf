provider "aws" {
  region = var.region

  # Default tags are stamped on every taggable resource: great for cost
  # allocation and for finding leftovers after an incomplete destroy.
  default_tags {
    tags = {
      Project     = var.project
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}
