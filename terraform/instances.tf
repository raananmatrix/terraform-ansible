resource "aws_instance" "ansible-server" {
  ami             = data.aws_ami.rhel.id
  instance_type   = var.instance_type
  security_groups = [ aws_security_group.allow_ssh.tags_all.Name ]
  key_name        = aws_key_pair.server.key_name
  tags            = {
    Name = "ansible-server"
  }
  provisioner "file" {
    content       = var.ansible_private_key
    destination   = "/home/ec2-user/.ssh/id_rsa"
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = var.ansible_private_key
      host        = self.public_ip
    }
  }
  provisioner "remote-exec" {
    inline        = [
      "sudo yum update -y",
      "sudo yum install -y python39 git",
      "python3 -m pip install --user ansible",
      "git clone https://github.com/raananmatrix/terraform-ansible.git",
      "sudo chown ec2-user:ec2-user /home/ec2-user/.ssh/id_rsa",
      "sudo chmod 0400 /home/ec2-user/.ssh/id_rsa",
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = var.ansible_private_key
      host        = self.public_ip
    }
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

