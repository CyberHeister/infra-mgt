output "aws_account_id" {
  description = "Account ID this module is pointed at. Worth reading before any apply - it is the cheapest guard against a wrong-account credential."
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "Region this module is pointed at."
  value       = var.aws_region
}
