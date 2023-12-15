provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "ec2_instance_example" {
  // AMI (amazon machine image) id for AWS Linux 2 in us-east-1
  ami = "ami-0dc2d3e4c0f9ebd18"
  instance_type = "t2.micro"
}
