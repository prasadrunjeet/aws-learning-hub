aws_region = "ap-south-1"

vpc_name = "counter"
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

visitor_counter_image = "445567100428.dkr.ecr.ap-south-1.amazonaws.com/visitor-counter/frontend:v1.0.0"