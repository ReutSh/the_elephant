 resource "aws_lb" "web-nginx" {
  name               = "nginx-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.module_vpc_reut.public_subnets_id
  security_groups    = [aws_security_group.nginx_instances_access.id]

  tags = merge(local.common_tags, map("Name", "nginx-alb-${module.module_vpc_reut.vpc_id}"))
}


resource "aws_lb_listener" "web-nginx" {
  load_balancer_arn = aws_lb.web-nginx.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-nginx.arn
  }
}

resource "aws_lb_target_group" "web-nginx" {
  name     = "nginx-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.module_vpc_reut.vpc_id

  health_check {
    enabled = true
    path    = "/"
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 60
  }

  tags = merge(local.common_tags, map("Name", "nginx-target-group-${module.module_vpc_reut.vpc_id}"))
}

resource "aws_lb_target_group_attachment" "web_server" {
  count            = length(aws_instance.nginx)
  target_group_arn = aws_lb_target_group.web-nginx.id
  target_id        = aws_instance.nginx.*.id[count.index]
  port             = 80
}
