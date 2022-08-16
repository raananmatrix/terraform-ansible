variable "ansible_private_key" {}

variable "server_public_key" {}

variable "instance_count" {
  default = 3
  type    = number
}

variable "instance_type" {
  default = "t2.micro"
  type    = string
}
