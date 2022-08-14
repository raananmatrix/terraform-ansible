terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

data "aws_ami" "rhel" {
  most_recent = true
  filter {
    name   = "name"
    values = ["309956199498/RHEL-8.6.0_HVM-*-x86_64-2-Hourly2-GP2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["309956199498"]
}

resource "aws_security_group" "allow_http_and_ssh" {
  name        = "allow_8080_and_ssh"
  description = "allow_8080_and_ssh"
  ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
  }
  tags = {
    Name = "allow_8080_and_ssh"
  }
}

resource "aws_key_pair" "server" {
  key_name   = "paris-key"
  public_key = var.server_public_key
}

resource "aws_instance" "web-server" {
  count           = var.instance_count
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  security_groups = [ aws_security_group.allow_http_and_ssh.tags_all.Name ]
  key_name        = aws_key_pair.server.key_name
  tags            = {
    Name = "web-server-${count.index}"
  }
}

resource "null_resource" "ansible-server" {
  depends_on    = [aws_instance.web-server]
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = var.ansible_private_key
    host        = var.ansible_host
  }
  provisioner "remote-exec" {
    inline = [
      "sleep 30 && ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -v -u ec2-user -T 60 -b -i ${join(",", aws_instance.web-server[*].public_ip)}, /home/ec2-user/playbooks/apache.yaml",
    ]
  }
}
