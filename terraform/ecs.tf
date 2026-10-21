resource "aws_ecs_cluster" "main" {
  name = "${var.vpc_name}-ecs"

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-ecs"
  })
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster."
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster."
  value       = aws_ecs_cluster.main.arn
}
