provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "ec2_instance_example" {
  ami = "ami-0dc2d3e4c0f9ebd18"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.sg_web_traffic.name]
}


variable "ingress_ports" {
  type = list(number)
  default = [
    // http
    80,
    // https
    443,
    // postgres
    5432,
    // ssh
    22,
  ]
}

resource "aws_security_group" "sg_web_traffic" {
  name = "SG example"

  // Iterate through list ingress_ports and create similar
  // reusable blocks with changing from_port and to_port
  dynamic "ingress" { // notice dynamic
    iterator = port
    for_each = var.ingress_ports
    content {
      from_port = port.value
      to_port = port.value
      protocol = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port = 443
    to_port = 443
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
