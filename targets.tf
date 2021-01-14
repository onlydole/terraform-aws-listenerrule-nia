resource "aws_lb_target_group" "canary" {
  name        = "${local.name.0}-${local.datacenter.0}"
  port        = local.port.0
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled = true
    path    = var.health_check_path
  }
}

resource "aws_lb_target_group_attachment" "app_canary" {
  for_each          = local.ip_addresses
  target_group_arn  = aws_lb_target_group.canary.arn
  target_id         = each.value
  port              = local.port.0
  availability_zone = "all"
}

resource "aws_lb_listener_rule" "app_canary" {
  listener_arn = var.listener_arn
  priority     = var.listener_rule_priority

  action {
    type = "forward"
    forward {
      target_group {
        arn    = var.blue_target_group_arn
        weight = 100 - var.green_weight
      }

      target_group {
        arn    = aws_lb_target_group.canary.arn
        weight = var.green_weight
      }

      stickiness {
        enabled  = true
        duration = 600
      }
    }
  }

  condition {
    host_header {
      values = [local.host.0]
    }
  }
}