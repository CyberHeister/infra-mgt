# bootstrap

Creates the S3 bucket that stores Terraform state for every other stack in this
repository. **Run once per AWS account, then leave alone.**

## Why this is a separate stack

The state bucket cannot be stored in the state it holds. This stack therefore
starts with local state, creates the bucket, and then migrates its own state
into that bucket — after which no `.tfstate` file remains on disk.

## What it creates

| Resource | Why |
|---|---|
| `aws_s3_bucket` | Holds state. Named `<project>-tfstate-<account-id>`, because bucket names are globally unique across all AWS accounts. |
| `aws_s3_bucket_versioning` | Recovery path for a corrupt or truncated state write. Without it, a bad write is unrecoverable. |
| `aws_s3_bucket_server_side_encryption_configuration` | State is plaintext; encrypt at rest (AES256). |
| `aws_s3_bucket_public_access_block` | State must never be publicly readable. All four flags on. |
| `aws_s3_bucket_ownership_controls` | `BucketOwnerEnforced` — disables ACLs entirely. |
| `aws_s3_bucket_policy` | Denies any request over plain HTTP (`aws:SecureTransport = false`). |

Six resources. No compute, no NAT, no billable-by-the-hour anything — S3 storage
for a few KB of state is effectively free.

The bucket carries `prevent_destroy = true`. A stray `terraform destroy` cannot
delete it, because doing so would leave every other stack's infrastructure
running with no Terraform record of it. To tear it down deliberately, remove the
`lifecycle` block in `main.tf` first.

## Prerequisites

Terraform >= 1.11 (see the comment in `versions.tf` for why the floor is hard),
and AWS credentials for the target account.

**`ap-south-2` (Hyderabad) is an opt-in region.** If it is not enabled on the
account, every command below fails with an authorization error that does not
mention the real cause. Check first:

```bash
aws ec2 describe-regions --region-names ap-south-2 --query 'Regions[0].OptInStatus' --output text
```

Expect `opted-in` or `opt-in-not-required`. Anything else: enable the region in
the AWS console before continuing.

## Run-once sequence

**1. Configure and review.**

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
```

Expect 6 to add, 0 to change, 0 to destroy. Confirm the bucket name in the plan
contains the account ID you expect — this is the cheapest moment to catch a
wrong-account credential.

**2. Create the bucket.**

```bash
terraform apply
```

Note the `state_bucket_name` output.

**3. Migrate this stack's state into the bucket it just created.**

Uncomment the `backend "s3"` block in `versions.tf`, paste in the bucket name,
then:

```bash
terraform init -migrate-state
```

Answer `yes` when prompted. Verify nothing is left behind:

```bash
ls *.tfstate 2>/dev/null || echo "clean - no local state"
```

**4. Point the root module at the bucket.** Replace the placeholder `bucket`
value in `../terraform/backend.tf` with the same name, then follow the root
[README](../README.md).
