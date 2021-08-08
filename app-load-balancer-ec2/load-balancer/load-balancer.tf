variable "subnetIds" {
  description = "The subnet IDs to deploy the load balancer to"
  type        = list(string)
}

variable "vpcId" {
  type = string
}

module "albSecurityGroup" {
  source = "./security-group"

  networkVpcId = var.vpcId
}

module "launchTemplate" {
  source = "./launch-template"
  secGroupAllowHttpAndHttpsId = module.albSecurityGroup.allowHttpAndHttpsId
}

resource "aws_alb" "clientLoadBalancer" {
  name            = "client-app-load-balancer"

  security_groups = [module.albSecurityGroup.allowHttpAndHttpsId]
  subnets = var.subnetIds

  load_balancer_type = "application"
}

resource "aws_alb_listener" "albListener" {
  load_balancer_arn = aws_alb.clientLoadBalancer.arn
  port = 80
  protocol = "HTTP"

  // by default, return simple 404 page
  default_action {
    type = "fixed-response"
    order = 1

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found!"
      status_code = "404"
    }
  }

}

resource "aws_lb_listener_rule" "forwardAllToTargetGroupASG" {
  listener_arn = aws_alb_listener.albListener.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.loadBalancerTargetGroup.arn
  }
}

resource "aws_lb_target_group" "loadBalancerTargetGroup" {

  name = "loadBalancerTargetGroup"

  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpcId

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_autoscaling_group" "appLoadBalancerAsg" {
  min_size = 2
  desired_capacity = 2
  max_size = 10
  vpc_zone_identifier = var.subnetIds

  health_check_type = "ELB"

  target_group_arns = [aws_lb_target_group.loadBalancerTargetGroup.arn]

  launch_template {
    id = module.launchTemplate.clientServer.id
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  // Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "appLoadBalancerAsg"
    propagate_at_launch = true
  }
}

resource "aws_cloudwatch_metric_alarm" "onCpuOverAlarm" {
  alarm_name = "onCpuOver60Alarm"
  alarm_description = "This metric monitors EC2 instance CPU utilization"
  evaluation_periods = "2"
  period = "120"
  threshold = "60"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name = "CPUUtilization"

  namespace = "AWS/EC2"
  statistic = "Average"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.appLoadBalancerAsg.name
  }

  alarm_actions = [ aws_autoscaling_policy.policyCpuOver.arn ]
}

resource "aws_autoscaling_policy" "policyCpuOver" {
  name = "webPolicyUp"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.appLoadBalancerAsg.name
}

resource "aws_cloudwatch_metric_alarm" "onCpuUnderAlarm" {
  alarm_description = "This metric monitors EC2 instance CPU under 10 utilization"
  alarm_name = "onCpuDownAlarm"

  metric_name = "CPUUtilization"
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold = "10"

  evaluation_periods = "2"
  period = "120"
  statistic = "Average"
  namespace = "AWS/EC2"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.appLoadBalancerAsg.name
  }

  alarm_actions = [ aws_autoscaling_policy.policyCpuUnder.arn ]
}

resource "aws_autoscaling_policy" "policyCpuUnder" {
  name = "policyCpuUnder"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.appLoadBalancerAsg.name
}

output "albDnsName" {
  value = aws_alb.clientLoadBalancer.dns_name
}
