variable "server_names" {
  type = list(string)
}

resource "aws_instance" "db" {
  ami = "ami-0dc2d3e4c0f9ebd18"
  instance_type = "t2.micro"

  count = length(var.server_names)
  tags = {
    Name = var.server_names[count.index]
  }
}

output "PrivateIp" {
  // notice * below due to it being 3 outputs because of
  // length(var.server_names)
  value = aws_instance.db.*.private_ip
}
