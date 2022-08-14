terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

variable "ansible_private_key" {}
variable "ansible_host" {}

resource "aws_instance" "web-server-1" {
  ami             = "ami-0460bf124812bebfa"
  instance_type   = "t2.micro"
  security_groups =  [ "MyWebSG" ]
  key_name        = "paris-key"
  tags = {
    Name = "web-server-1"
  }
}

resource "null_resource" "ansible-server" {
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = "${var.ansible_private_key}"
    host        = "${var.ansible_host}"
  }
  provisioner "remote-exec" {
    inline = [
      "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user -b --private-key ${var.ansible_private_key} -i ${aws_instance.web-server-1.public_ip}, /home/ec2-user/playbooks/apache.yaml",
    ]
  }
}
