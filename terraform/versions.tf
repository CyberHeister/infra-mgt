terraform {
  # >= 1.11 is required, not merely recommended. Native S3 state locking
  # (use_lockfile in backend.tf) went GA in 1.11, which is what lets this
  # project skip a DynamoDB lock table entirely. On an older CLI the argument
  # is not honoured and concurrent applies can corrupt state.
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
