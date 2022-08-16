resource "aws_lb" "web-servers-lb" {
  name               = "web-servers-lb"
  internal           = false
  load_balancer_type = "network"
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_target_group" "web-servers-target-group" {
  name     = "web-servers-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

resource "aws_lb_target_group_attachment" "web-servers-attachment" {
  count = length(aws_instance.web-server)
  target_group_arn = aws_lb_target_group.web-servers-target-group.arn
  port             = 8080
  target_id        = aws_instance.web-server[count.index].id
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.web-servers-lb.arn
  port              = "80"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-servers-target-group.arn
  }
}
