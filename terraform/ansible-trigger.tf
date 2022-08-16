resource "null_resource" "ansible-server" {
  triggers = {
    web_server_arns = join(",", aws_instance.web-server.*.arn)
  }
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = var.ansible_private_key
    host        = aws_instance.ansible-server.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sleep 30 && ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -v -u ec2-user --private-key /home/ec2-user/.ssh/id_rsa -b -i ${join(",", aws_instance.web-server[*].public_ip)}, /home/ec2-user/terraform-ansible/ansible/apache.yaml",
    ]
  }
}
