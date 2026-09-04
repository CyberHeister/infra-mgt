# infra-mgt

Infrastructure management for AWS, using Terraform as IaC and Jenkins as the
CI/CD medium.

DevOps Projects

## Status

Scaffolding stage. The root module deliberately creates **no billable
resources** yet — it exists so the backend, credentials, and Jenkins wiring can
be proven end-to-end before any real infrastructure is added.

## Layout

```
bootstrap/     Run-once stack that creates the S3 state bucket. See bootstrap/README.md.
terraform/     The root module. This is what Jenkins plans and applies.
Jenkinsfile    Build/test/docker stages for the app, plus the Terraform stages.
```

Environments are not split yet: one root module, one state file. The migration
path to a per-environment layout is noted at the bottom of
[terraform/main.tf](terraform/main.tf).

## Prerequisites

- **Terraform >= 1.11.** The floor is hard, not advisory. Native S3 state
  locking (`use_lockfile`) went GA in 1.11 and is what lets this project skip a
  DynamoDB lock table. On an older CLI the argument is silently ignored and
  concurrent applies can corrupt state.

  ```bash
  brew tap hashicorp/tap && brew install hashicorp/tap/terraform
  ```

- AWS credentials for the target account.

- **`ap-south-2` (Hyderabad) must be opted in.** It is not enabled by default,
  and when it is missing every command fails with an authorization error that
  never mentions the real cause:

  ```bash
  aws ec2 describe-regions --region-names ap-south-2 --query 'Regions[0].OptInStatus' --output text
  ```

  Expect `opted-in` or `opt-in-not-required`.

## First-time setup

**1. Create the state bucket.** Follow [bootstrap/README.md](bootstrap/README.md).
It creates the bucket, then migrates its own state into it so nothing is left on
disk.

**2. Point the root module at the bucket.** Replace the `REPLACE_ME-...`
placeholder in [terraform/backend.tf](terraform/backend.tf) with the
`state_bucket_name` output from step 1.

Until that placeholder is replaced, the Jenkins `Terraform` stage skips itself
by design rather than failing every build on `terraform init`.

**3. Verify.**

```bash
cd terraform && terraform init && terraform validate && terraform plan
```

Expect `Success! The configuration is valid.` and a plan with **0 to add, 0 to
change, 0 to destroy**. On the very first run it will also report
`Changes to Outputs:` for the two outputs — that is expected, outputs are not
infrastructure and cost nothing.

A plan that succeeds while creating nothing is the useful signal here: it proves
credentials resolve, the region is reachable and opted-in, and the S3 backend is
readable and lockable.

**4. Confirm locking is actually active.** This is the check most easily skipped
and the one protecting against concurrent-apply corruption. While a
`terraform plan` is running, from a second shell:

```bash
aws s3 ls s3://<state-bucket>/infra-mgt/
```

A `terraform.tfstate.tflock` object should appear for the duration and vanish
afterwards. If it never appears, `use_lockfile` is not in effect — recheck
`terraform version` against the 1.11 floor.

## Day-to-day

```bash
cd terraform
terraform plan -out=tfplan
terraform apply tfplan
```

Always apply a saved plan rather than a bare `terraform apply`, so what was
reviewed is what lands.

`terraform.tfvars` is gitignored. Copy `terraform.tfvars.example` if you need to
override defaults locally.

## Pipeline behaviour

| Stage | Runs when |
|---|---|
| Format / Init / Validate / Plan | Every branch, once the backend is configured |
| Apply | `main` only, and only after manual approval in the Jenkins UI |

Notes:

- `Apply` consumes the plan file produced by `Plan`, so the approved diff is the
  applied diff.
- The human-readable plan is archived as `tfplan.txt` inside the `Plan` stage,
  which runs before the `cleanWs()` in `post.always` — otherwise it would be
  deleted with the workspace.
- `when { branch 'main' }` is only populated by Multibranch Pipeline jobs. In a
  plain pipeline job it evaluates false and `Apply` is skipped, which is the
  safe direction to fail.
- AWS authentication for the pipeline is **not chosen yet**. The three candidate
  mechanisms are documented in a comment above the `Terraform` stage in the
  [Jenkinsfile](Jenkinsfile).

## State safety

- State stores values in plaintext, including generated passwords and keys.
  `.gitignore` excludes `*.tfstate` and `*.tfvars` for that reason. Verify with
  `git status --porcelain` before committing.
- `.terraform.lock.hcl` **is** tracked, so CI and every developer resolve
  identical provider versions.
- The state bucket carries `prevent_destroy = true` and has versioning enabled.
