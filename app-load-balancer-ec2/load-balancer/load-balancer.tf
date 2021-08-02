variable "subnetIds" {
  description = "The subnet IDs to deploy to"
  type        = list(string)
}

variable "networkVpcId" {
  type = string
}

module "albSecurityGroup" {
  source = "./security-group"

  networkVpcId = var.networkVpcId
}

module "launchTemplate" {
  source = "./launch-template"

  sgAllowHttpAndHttpsId = module.albSecurityGroup.allowHttpAndHttpsId
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

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_alb_listener.albListener.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

resource "aws_lb_target_group" "asg" {

  name = aws_alb.clientLoadBalancer.name //TODO

  port     = 80
  protocol = "HTTP"
  vpc_id   = var.networkVpcId

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

// TODO is this needed?
locals {
  httpPort = 80
  anyPort = 0
  anyProtocol = "-1"
  tcpProtocol = "tcp"
  allIps = ["0.0.0.0/0"]
}

resource "aws_autoscaling_group" "clientASG" {
  min_size = 1
  desired_capacity = 2
  max_size = 4

  health_check_type = "ELB"

  target_group_arns = [aws_lb_target_group.asg.arn]

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

  vpc_zone_identifier = var.subnetIds

  // Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "web"
    propagate_at_launch = true
  }
}


resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_up" {
  alarm_name = "web_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "60"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.clientASG.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.web_policy_up.arn ]
}

resource "aws_autoscaling_policy" "web_policy_up" {
  name = "web_policy_up"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.clientASG.name
}

resource "aws_autoscaling_policy" "web_policy_down" {
  name = "web_policy_down"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.clientASG.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_down" {
  alarm_name = "web_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "10"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.clientASG.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.web_policy_down.arn ]
}

output "albDnsName" { // TODO NEEDED?
  value = aws_alb.clientLoadBalancer.dns_name
}
