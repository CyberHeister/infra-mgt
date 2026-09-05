variable "aws_region" {
  description = "Region to create resources in. Must match the region in backend.tf."
  type        = string
  default     = "ap-south-2"
}

variable "project" {
  description = "Project slug, applied as the Project tag on every resource."
  type        = string
  default     = "infra-mgt"
}

variable "environment" {
  description = "Environment name, applied as the Environment tag on every resource."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}
