variable "ec2_name" {
  type = string

}
resource "aws_instance" "ec2_module_example" {
  ami = "ami-0dc2d3e4c0f9ebd18"
  instance_type = "t2.micro"
  tags = {
    Name = var.ec2_name
  }
}

output "instance_id" {
  value = aws_instance.ec2_module_example.id
}
