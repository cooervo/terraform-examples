provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "database" {
  ami = "ami-0dc2d3e4c0f9ebd18"
  instance_type = "t2.micro"
}


resource "aws_instance" "web" {
  ami = "ami-0dc2d3e4c0f9ebd18"
  instance_type = "t2.micro"

  // notice this instance has a dependency on database instance
  depends_on = [aws_instance.database]
}
