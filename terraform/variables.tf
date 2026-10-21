variable "aws_region" {
  description = "AWS region in which to create the infrastructure."
  type        = string
}

variable "visitor_counter_image" {
  description = "Full container image URI for the visitor-counter backend."
  type        = string

  validation {
    condition     = length(trimspace(var.visitor_counter_image)) > 0
    error_message = "Set visitor_counter_image to a non-empty container image URI."
  }
}

variable "vpc_name" {
  description = "Name prefix for VPC resources."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Exactly two public subnet CIDRs are required."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Exactly two private subnet CIDRs are required."
  }
}

variable "tags" {
  description = "Additional tags to apply to VPC resources."
  type        = map(string)
}
