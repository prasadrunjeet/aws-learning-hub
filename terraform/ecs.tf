resource "aws_ecs_cluster" "main" {
  name = "${var.vpc_name}-ecs"

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-ecs"
  })
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.vpc_name}-ecs-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "visitor_counter" {
  name              = "/ecs/${var.vpc_name}-visitor-counter"
  retention_in_days = 30

  tags = var.tags
}

resource "aws_ecs_task_definition" "visitor_counter" {
  family                   = "${var.vpc_name}-visitor-counter"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "visitor-counter"
      image     = var.visitor_counter_image
      essential = true
      portMappings = [{
        containerPort = 8000
        hostPort      = 8000
        protocol      = "tcp"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.visitor_counter.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = var.tags
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster."
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster."
  value       = aws_ecs_cluster.main.arn
}

output "visitor_counter_task_definition_arn" {
  description = "ARN of the visitor-counter Fargate task definition."
  value       = aws_ecs_task_definition.visitor_counter.arn
}
