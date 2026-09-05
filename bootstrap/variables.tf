variable "aws_region" {
  description = "Region to create the Terraform state bucket in. Must match the region set in terraform/backend.tf."
  type        = string
  default     = "ap-south-2"
}

variable "project" {
  description = "Project slug used to prefix the state bucket name."
  type        = string
  default     = "infra-mgt"

  validation {
    # The slug becomes part of an S3 bucket name, which forbids uppercase and
    # underscores. Catching it here beats a provider-level error mid-apply.
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.project))
    error_message = "project must be lowercase alphanumeric with hyphens, and must not start or end with a hyphen."
  }
}
