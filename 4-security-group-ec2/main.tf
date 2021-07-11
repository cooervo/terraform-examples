provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "ec2_instance_example" {
  ami = "ami-0dc2d3e4c0f9ebd18"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.web_traffic.name]
}

resource "aws_security_group" "web_traffic" {
  name = "Allow HTTPS"

  ingress {
    from_port = 443
    to_port = 443
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 443
    to_port = 443
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
