#!/usr/bin/env bash
set -euo pipefail

bucket_name="${1:-}"
region="${2:-${AWS_REGION:-}}"

if [[ -z "$bucket_name" || -z "$region" ]]; then
  printf 'Usage: %s <globally-unique-bucket-name> <aws-region>\n' "$0" >&2
  exit 1
fi

if ! command -v aws >/dev/null 2>&1; then
  printf 'Error: AWS CLI is required.\n' >&2
  exit 1
fi

aws sts get-caller-identity >/dev/null

create_args=(--bucket "$bucket_name" --region "$region")
if [[ "$region" != "us-east-1" ]]; then
  create_args+=(--create-bucket-configuration "LocationConstraint=$region")
fi

if aws s3api head-bucket --bucket "$bucket_name" >/dev/null 2>&1; then
  printf 'Using existing bucket: %s\n' "$bucket_name"
else
  printf 'Creating bucket: %s (%s)\n' "$bucket_name" "$region"
  aws s3api create-bucket "${create_args[@]}"
fi

aws s3api put-bucket-versioning \
  --bucket "$bucket_name" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket "$bucket_name" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws s3api put-public-access-block \
  --bucket "$bucket_name" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

aws s3api put-bucket-ownership-controls \
  --bucket "$bucket_name" \
  --ownership-controls '{"Rules":[{"ObjectOwnership":"BucketOwnerEnforced"}]}'

printf '\nState bucket is ready. Add these values to GitHub Actions repository variables:\n'
printf '  TF_STATE_BUCKET=%s\n' "$bucket_name"
printf '  AWS_REGION=%s\n' "$region"
printf '\nTerraform initialization command:\n'
printf '  terraform init -backend-config="bucket=%s" -backend-config="region=%s"\n' "$bucket_name" "$region"
