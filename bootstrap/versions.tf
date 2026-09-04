terraform {
  # >= 1.11 is required, not merely recommended. Native S3 state locking
  # (use_lockfile) went GA in 1.11, which is what lets this project skip a
  # DynamoDB lock table entirely. On an older CLI the argument is not honoured
  # and concurrent applies can corrupt state.
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # This stack creates the bucket that holds every other stack's state, so it
  # cannot start out storing its state there. It runs first with local state,
  # then moves into the bucket it just made.
  #
  # Bootstrap step 3: once `terraform apply` below has succeeded, uncomment this
  # block, paste in the `state_bucket_name` output, and run:
  #
  #     terraform init -migrate-state
  #
  # After that no .tfstate file is left on disk to accidentally commit.
  #
  # backend "s3" {
  #   bucket       = "<state_bucket_name output>"
  #   key          = "bootstrap/terraform.tfstate"
  #   region       = "ap-south-2"
  #   encrypt      = true
  #   use_lockfile = true
  # }
}
