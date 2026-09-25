aws_region = "ap-south-1"

vpc_name = "aws-learning-hub-vpc"
vpc_cidr = "192.168.0.0/16"

public_subnet_cidrs = [
  "192.168.1.0/24",
  "192.168.2.0/24"
]

private_subnet_cidrs = [
  "192.168.11.0/24",
  "192.168.12.0/24"
]

tags = {
  Project   = "aws-learning-hub"
  ManagedBy = "Terraform"
}
