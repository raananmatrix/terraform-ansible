output "web_server_load_balancer_dns" {
  value = aws_lb.web-servers-lb.dns_name
}
