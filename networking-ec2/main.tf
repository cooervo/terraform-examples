provider "aws" {
  region = "us-east-1"
}

// 1. Create a VPC
resource "aws_vpc" "clientVpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "VPC for the client tier"
  }
}

// 2. Create Internet Gateway
resource "aws_internet_gateway" "clientInternetGateway" {
  vpc_id = aws_vpc.clientVpc.id
}

// 3. Create Custom Route Table
resource "aws_route_table" "clientRouteTable" {
  vpc_id = aws_vpc.clientVpc.id

  // IPv4: all IPv4 traffic passes through defined IGateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.clientInternetGateway.id
  }

  // IPv6
  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.clientInternetGateway.id
  }

  tags = {
    Name = "Client Route Table"
  }
}

// 4. Create a Subnet
resource "aws_subnet" "clientSubnet" {
  cidr_block = "10.0.1.0/24"
  vpc_id = aws_vpc.clientVpc.id
  availability_zone = "us-east-1a"

  tags = {
    Name = "Client Subnet"
  }
}

// 5. Associate Subnet with Route table
resource "aws_route_table_association" "routeTableAssociation" {
  subnet_id = aws_subnet.clientSubnet.id
  route_table_id = aws_route_table.clientRouteTable.id
}

// 6. Create Security Group to allow port 22 (ssh), 80 (http) and 443 (https)
resource "aws_security_group" "securityGroupAllowSshHttpAndHttps" {
  name        = "allow web traffic"
  vpc_id      = aws_vpc.clientVpc.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

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

// 7. Create Network Interface with an IP in the subnet created in step 4
resource "aws_network_interface" "clientNetworkInterface" {
  subnet_id = aws_subnet.clientSubnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.securityGroupAllowSshHttpAndHttps.id]
}


// 8. Assign an Elastic IP to the Network Interface created in step 7
resource "aws_eip" "clientElasticIP" {
  vpc                       = true
  network_interface         = aws_network_interface.clientNetworkInterface.id
  associate_with_private_ip = "10.0.1.50" // TODO use local var or input
  depends_on = [aws_internet_gateway.clientInternetGateway]
}

// 9. Create Ubuntu instance and install apache server in it.
resource "aws_instance" "clientServer" {
  ami = "ami-0747bdcabd34c712a" // free tier ubuntu AMI
  instance_type = "t2.micro"
  availability_zone = "us-east-1a" // TODO use local var or input
  key_name = "ec2-key-pairs"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.clientNetworkInterface.id
  }

  user_data = <<-EOF
            #!/bin/bash
            sudo apt update -y
            sudo apt install apache2 -y
            sudo systemctl start apache2
            sudo bash -c 'echo ClientServer running > /var/www/html/index.html'
            EOF
  tags = {
    Name = "Client Server"
  }
}
