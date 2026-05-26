provider "aws" {
  region = "eu-north-1"
}

resource "aws_launch_template" "home_temp" {
  name          = "home-temp"
  image_id      = "ami-05d62b9bc5a6ca605"
  instance_type = "t3.micro"
  key_name      = "gauchan"

  user_data = base64encode(<<-EOF
      #!/bin/bash
      apt update -y
      apt install nginx -y
      echo "this is home page" > /var/www/html/index.html
      systemctl start nginx
      systemctl enable nginx
  EOF
  )

  tags = {
    Name = "MyFirstEc2"
  }
}

resource "aws_launch_template" "cloth_temp" {
  name          = "cloth-temp"
  image_id      = "ami-05d62b9bc5a6ca605"
  instance_type = "t3.micro"
  key_name      = "gauchan"

  user_data = base64encode(<<-EOF
      #!/bin/bash
      apt update -y
      apt install nginx -y

      mkdir -p /var/www/html/cloth

      echo "Sale Sale" > /var/www/html/cloth/index.html

      chmod -R 755 /var/www/html/cloth

      systemctl start nginx
      systemctl enable nginx
  EOF
  )

  tags = {
    Name = "MyFirstEc2"
  }
}

resource "aws_autoscaling_group" "auto_home" {
  name                      = "auto-home"
  availability_zones        = ["ap-south-1a"]
  desired_capacity          = 2
  max_size                  = 4
  min_size                  = 2
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.home_temp.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_group" "auto_cloth" {
  name                      = "auto-cloth"
  availability_zones        = ["ap-south-1a"]
  desired_capacity          = 2
  max_size                  = 5
  min_size                  = 2
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.cloth_temp.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "home_policy" {
  name                   = "home-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.auto_home.name
}

resource "aws_autoscaling_policy" "cloth_policy" {
  name                   = "cloth-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.auto_cloth.name
}

resource "aws_cloudwatch_metric_alarm" "home_alarm" {
  alarm_name          = "home-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.auto_home.name
  }

  alarm_actions = [aws_autoscaling_policy.home_policy.arn]
}

resource "aws_cloudwatch_metric_alarm" "cloth_alarm" {
  alarm_name          = "cloth-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.auto_cloth.name
  }

  alarm_actions = [aws_autoscaling_policy.cloth_policy.arn]
}

resource "aws_lb_target_group" "target_home" {
  name        = "target-home"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "vpc-078bd8e712c390226"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_target_group" "target_cloth" {
  name        = "target-cloth"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "vpc-078bd8e712c390226"

  health_check {
    path                = "/cloth"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_autoscaling_attachment" "attach_home" {
  autoscaling_group_name = aws_autoscaling_group.auto_home.id
  lb_target_group_arn    = aws_lb_target_group.target_home.arn
}

resource "aws_autoscaling_attachment" "attach_cloth" {
  autoscaling_group_name = aws_autoscaling_group.auto_cloth.id
  lb_target_group_arn    = aws_lb_target_group.target_cloth.arn
}

resource "aws_lb" "load_balancer" {
  name               = "load-balancer"
  internal           = false
  load_balancer_type = "application"

  security_groups = ["sg-0e9c1bb98fd05a9b6"]

  subnets = [
    "subnet-0d08b645f6da2388a",
    "subnet-09fd71062b3c06661"
  ]
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_home.arn
  }
}

resource "aws_lb_listener_rule" "cloth_rule" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_cloth.arn
  }

  condition {
    path_pattern {
      values = ["/cloth*"]
    }
  }
}
