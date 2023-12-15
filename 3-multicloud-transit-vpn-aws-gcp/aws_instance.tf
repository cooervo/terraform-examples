data "aws_ami" "amazon_linux_2023" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.2.20231113.0-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_instance" "linux_amazon_ami_instance" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  subnet_id                   = aws_subnet.main[0].id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.mysg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              
              sudo yum install -y docker
              
              sudo service docker start
              
              sudo usermod -a -G docker ec2-user
              
              sudo chkconfig docker on

              docker pull cooervo/simple-nodejs
              
              sudo docker run -d -p 80:3000 cooervo/simple-nodejs "Hi from AWS!"
              EOF
  tags = {
    Name = "example-linux-amazon-instance"
  }
}

resource "aws_security_group" "mysg" {
  name        = "sg_example2"
  description = "My security group"
  vpc_id      = aws_vpc.main.id
}

# Security Group rule 1: Allow all outgoing traffic for any protocol
resource "aws_security_group_rule" "out_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.mysg.id
}

resource "aws_security_group_rule" "in_all" { # TODO DELETE
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.mysg.id
}

# Security Group rule 2: Allow SSH (TCP 22) incoming traffic from anywhere
resource "aws_security_group_rule" "in_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.mysg.id
}

# Security Group rule 3: Allow ICMP ingress packages only from GCP CIDR range in var
resource "aws_security_group_rule" "in_icmp" {
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = [var.gcp_cidr]
  security_group_id = aws_security_group.mysg.id
}

# Security Group rule 3: Allow ICMP egress everywhere
resource "aws_security_group_rule" "out_icmp" {
  type              = "egress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.mysg.id
}

# // pem file needed to ssh into ec2 instance
# resource "tls_private_key" "this" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# resource "aws_key_pair" "this" {
#   key_name   = "aws-key"
#   public_key = tls_private_key.this.public_key_openssh

#   provisioner "local-exec" {
#     command = <<-EOT
#       echo "${tls_private_key.this.private_key_pem}" > aws-key.pem
#     EOT
#   }
# }
