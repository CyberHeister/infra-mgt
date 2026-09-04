provider "aws" {
  region = var.aws_region

  # Applied to every taggable resource this module creates, so individual
  # resources do not need their own tag blocks for these three.
  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
