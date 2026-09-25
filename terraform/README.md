# Terraform

This directory contains the Terraform root configuration and reusable VPC
module for the visitor counter infrastructure.

## VPC architecture

The configuration creates a VPC in `ap-south-1` with CIDR `192.168.0.0/16`.
The first two available Availability Zones in the region are used.

| Tier | Subnet | CIDR | Internet path |
| --- | --- | --- | --- |
| Public | Public 1 | `192.168.1.0/24` | Internet Gateway |
| Public | Public 2 | `192.168.2.0/24` | Internet Gateway |
| Private | Private 1 | `192.168.11.0/24` | NAT Gateway 1 |
| Private | Private 2 | `192.168.12.0/24` | NAT Gateway 2 |

Each public subnet has a NAT Gateway with an Elastic IP. Each private subnet
has its own route table and sends `0.0.0.0/0` through the NAT Gateway in the
same Availability Zone. Private subnets can initiate outbound connections,
but they do not accept direct inbound connections from the internet.

```mermaid
flowchart LR
	users((Users))
	internet((Internet))
	igw[Internet Gateway]

	subgraph vpc["VPC 192.168.0.0/16"]
		direction LR

		subgraph az1["Availability Zone 1"]
			public1["Public subnet 1<br/>192.168.1.0/24"]
			nat1["NAT Gateway 1<br/>Elastic IP"]
			private1["Private subnet 1<br/>192.168.11.0/24"]
			privateRoute1["Private route table 1<br/>0.0.0.0/0 -> NAT 1"]

			public1 --> nat1
			private1 --> privateRoute1 --> nat1
		end

		subgraph az2["Availability Zone 2"]
			public2["Public subnet 2<br/>192.168.2.0/24"]
			nat2["NAT Gateway 2<br/>Elastic IP"]
			private2["Private subnet 2<br/>192.168.12.0/24"]
			privateRoute2["Private route table 2<br/>0.0.0.0/0 -> NAT 2"]

			public2 --> nat2
			private2 --> privateRoute2 --> nat2
		end

		publicRoute["Public route table<br/>0.0.0.0/0 -> IGW"]
		publicRoute --> public1
		publicRoute --> public2
	end

	users --> internet --> igw --> publicRoute
	nat1 --> igw
	nat2 --> igw

	classDef edge fill:#e8f1fb,stroke:#4b76a8,color:#172b4d
	classDef public fill:#e7f4e4,stroke:#4d8b4d,color:#193b19
	classDef private fill:#fff1db,stroke:#c88a2e,color:#51350d
	classDef gateway fill:#f9e2e2,stroke:#bd4b4b,color:#521b1b

	class users,internet edge
	class public1,public2,publicRoute public
	class private1,private2,privateRoute1,privateRoute2 private
	class igw,nat1,nat2 gateway
```

The VPC is implemented as the reusable local module in
`modules/vpc`. Root-level values are defined in `variables.tf` and supplied
through `terraform.tfvars`.

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

## Deployment requirements

1. Add AWS credentials through GitHub Actions OIDC and restrict the role to the intended environment.
2. Review the plan before applying infrastructure changes.
3. Review the destroy plan before confirming deletion.

## Run locally

Initialize the backend using the state bucket created by `bootstrap-state.sh`:

```bash
terraform init -backend-config="bucket=$TF_STATE_BUCKET" -backend-config="region=$AWS_REGION"
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

The Terraform deployment workflow runs automatically for changes under
`terraform/` pushed to `main`, and can also be started manually. The destroy
workflow is manual and requires typing `DESTROY` as confirmation.

NAT Gateways and their Elastic IPs incur AWS charges while they exist. Use the
destroy workflow only after reviewing its plan when the environment is no
longer needed.
