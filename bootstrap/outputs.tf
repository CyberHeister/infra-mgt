output "state_bucket_name" {
  description = "Name of the S3 bucket holding Terraform state. Paste this into terraform/backend.tf and into the commented backend block in bootstrap/versions.tf."
  value       = aws_s3_bucket.state.bucket
}

output "state_bucket_region" {
  description = "Region of the state bucket. Must match the region argument in terraform/backend.tf."
  value       = var.aws_region
}

output "state_bucket_arn" {
  description = "ARN of the state bucket, for writing the IAM policy that grants CI access to state."
  value       = aws_s3_bucket.state.arn
}
