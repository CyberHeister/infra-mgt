# Reading caller identity keeps `terraform plan` meaningful while this module is
# still empty. It forces a real authenticated API call, so a plan that succeeds
# with no changes proves the whole chain works: credentials resolve, the region
# is reachable and opted-in, and the S3 backend is readable and lockable.
#
# It is a data source, not a resource: nothing is created and nothing is billed.
data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# Real infrastructure goes below.
#
# Environments are not split yet - this is a single root module with one state
# file. When a second environment is needed, the migration is: create envs/<name>
# directories, give each its own backend `key`, move shared code into modules/,
# and `terraform state mv` the existing resources into the new dev state.
# ---------------------------------------------------------------------------
