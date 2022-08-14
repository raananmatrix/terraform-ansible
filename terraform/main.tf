terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
/*
  test
*/

resource "aws_instance" "web-server-1" {
  ami             = "ami-0460bf124812bebfa"
  instance_type   = "t2.micro"
  security_groups =  [ "MyWebSG" ]
  key_name        = "paris-key"
  tags = {
    Name = "web-server-1"
  }
}
