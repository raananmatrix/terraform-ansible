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
    values = ["RHEL-8.6.0_HVM-*-x86_64-2-Hourly2-GP2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["309956199498"]
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "allow_ssh"
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_security_group" "allow_http_and_ssh" {
  name        = "allow_8080_and_ssh"
  description = "allow_8080_and_ssh"
  ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_8080_and_ssh"
  }
}

resource "aws_key_pair" "server" {
  key_name   = "paris-key"
  public_key = var.server_public_key
}

resource "aws_instance" "ansible-server" {
  ami             = data.aws_ami.rhel.id
  instance_type   = var.instance_type
  security_groups = [ aws_security_group.allow_ssh.tags_all.Name ]
  key_name        = aws_key_pair.server.key_name
  tags            = {
    Name = "ansible-server"
  }
  provisioner "remote-exec" {
    inline        = [
      "sudo yum update -y",
      "sudo yum install -y python39 git",
      "python3 -m pip install --user ansible",
      "git clone https://github.com/raananmatrix/terraform-ansible.git",
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = var.ansible_private_key
      host        = self.public_ip
    }
  }
  provisioner "file" {
    content       = var.ansible_private_key
    destination   = "/home/ec2-user/.ssh/id_rsa"
  }
}

resource "aws_instance" "web-server" {
  count           = var.instance_count
  ami             = data.aws_ami.rhel.id
  instance_type   = var.instance_type
  security_groups = [ aws_security_group.allow_http_and_ssh.tags_all.Name ]
  key_name        = aws_key_pair.server.key_name
  tags            = {
    Name = "web-server-${count.index}"
  }
}

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
