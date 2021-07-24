provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "instance_example" {
  ami = "ami-0dc2d3e4c0f9ebd18"
  instance_type = "t2.micro"
}

// Creates an Elastic IP attached to "instance_example"
resource "aws_eip" "elastic_ip" {
  instance = aws_instance.instance_example.id
}

output "EIP" {
  value = aws_eip.elastic_ip.public_ip
}
