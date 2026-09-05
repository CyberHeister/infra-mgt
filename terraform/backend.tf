terraform {
  backend "s3" {
    # SETUP REQUIRED: replace with the `state_bucket_name` output from the
    # bootstrap stack. Until this is replaced, `terraform init` fails here and
    # the Jenkins Terraform stages skip themselves (see the `when` gate in the
    # Jenkinsfile) rather than reporting a red build.
    bucket = "REPLACE_ME-tfstate-000000000000"

    # Namespaced rather than sitting at the bucket root, so this bucket can host
    # additional stacks later without moving anything.
    key    = "infra-mgt/terraform.tfstate"
    region = "ap-south-2"

    encrypt = true

    # Native S3 locking, GA in Terraform 1.11. Replaces the DynamoDB lock table
    # the older pattern required. Writes a .tflock object alongside the state
    # for the duration of a plan or apply.
    use_lockfile = true
  }
}
