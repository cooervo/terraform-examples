provider "aws" {
  region = "us-east-1"
}

variable "number_of_servers" {
  type = number
}

resource "aws_instance" "ec2_example" {
  ami = "ami-0dc2d3e4c0f9ebd18"
  instance_type = "t2.micro"
  count = var.number_of_servers
}
