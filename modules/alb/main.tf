resource "aws_alb" "alb" {
  name               = var.name
  internal           = false
  load_balancer_type = "application"

  security_groups = [var.security_group_id]
  subnets         = var.subnet_ids

  tags = {
    name = var.name
  }
}