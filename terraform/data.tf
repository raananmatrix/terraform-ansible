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

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

