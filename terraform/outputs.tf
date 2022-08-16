output "web_server_load_balancer_dns" {
  value = aws_lb_listener.front_end.dns_name
}
