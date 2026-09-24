# Terraform

This directory is the Terraform root used by the manual destroy workflow.

The S3 backend stores state at `visitor-counter/terraform.tfstate` and uses
Terraform's native S3 lockfile support. The state bucket must be created before
running Terraform.

## Bootstrap the state bucket

Use a globally unique bucket name and an AWS region:

```bash
./bootstrap-state.sh my-unique-visitor-counter-tfstate ap-south-1
```

The script enables versioning, server-side encryption, S3 public-access
blocking, and bucket-owner-enforced object ownership. It is safe to run again
for an existing bucket. The caller needs permission to manage the bucket and
to call `sts:GetCallerIdentity`.

Set the printed `TF_STATE_BUCKET` and `AWS_REGION` as GitHub Actions repository
variables. Also set `AWS_ROLE_ARN` to a restricted IAM role trusted by this
repository's GitHub Actions OIDC provider. The role needs Terraform state
access to the bucket, including `GetObject`, `PutObject`, and `DeleteObject`
for both the state object and its `.tflock` object.

Before adding real resources:

1. Add the resources and a separate plan/apply workflow.
2. Add AWS credentials through GitHub Actions OIDC and restrict the role to the intended environment.
3. Review the destroy plan before confirming deletion.

To run locally:

```bash
terraform init -backend-config="bucket=$TF_STATE_BUCKET" -backend-config="region=$AWS_REGION"
terraform validate
terraform plan -destroy
```
