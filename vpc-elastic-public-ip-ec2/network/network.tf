variable "availabilityZoneInput" {
  type = string
}

locals {
  privateIp = "10.0.1.50"
}

// 1. Create a VPC
resource "aws_vpc" "clientVpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "VPC for the app"
  }
}

// 2. Create Internet Gateway
// Allows communication between your VPC and the public internet.
resource "aws_internet_gateway" "clientInternetGateway" {
  vpc_id = aws_vpc.clientVpc.id
}

// 3. Create a Subnet
resource "aws_subnet" "clientSubnet" {
  cidr_block = "10.0.1.0/24"
  vpc_id = aws_vpc.clientVpc.id
  availability_zone = var.availabilityZoneInput

  tags = {
    Name = "Client Subnet"
  }
}

// 4. Create Custom Route Table
// Determines where network traffic from your subnet or gateway is directed.
resource "aws_route_table" "clientRouteTable" {
  vpc_id = aws_vpc.clientVpc.id

  // All IPv4 traffic should be directed to through the defined Int.Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.clientInternetGateway.id
  }

  // All IPv6 traffic should be directed through the defined Int.Gateway
  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.clientInternetGateway.id
  }

  tags = {
    Name = "Client Route Table"
  }
}

// 5. Associate Subnet with Route table
// To make a subnet public add a route in our subnet's route table to an Int.Gateway
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
  private_ips     = [local.privateIp]
  security_groups = [aws_security_group.securityGroupAllowSshHttpAndHttps.id]
}

output "clientNetworkInterfaceId" {
  value = aws_network_interface.clientNetworkInterface.id
  description = "ID of the Network Interface"
}


// 8. Assign an Elastic IP to the Network Interface created in step 7
resource "aws_eip" "clientElasticIP" {
  vpc                       = true
  network_interface         = aws_network_interface.clientNetworkInterface.id
  associate_with_private_ip = local.privateIp
  depends_on = [aws_internet_gateway.clientInternetGateway]
}

output "clientElasticIp" {
  value = aws_eip.clientElasticIP.public_ip
  description = "Public IP of the Elastic IP"
}
