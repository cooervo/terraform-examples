variable "networkVpcId" {
  type = string
  description = "The VPC id"
}

// Create Security Group to allow ports 80 (http) and 443 (https)
resource "aws_security_group" "securityGroupAllowHttpAndHttps" {
  name        = "allow web traffic"
  vpc_id      = var.networkVpcId

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  // allow egress everywhere
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Allow SSH,HTTP and HTTPS"
  }
}

output "allowHttpAndHttpsId" {
  value = aws_security_group.securityGroupAllowHttpAndHttps.id
}
