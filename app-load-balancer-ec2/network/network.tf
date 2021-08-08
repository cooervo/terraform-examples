locals {
  allIps = "0.0.0.0/0"
  allIpsV6 = "::/0"
}

variable "subnetsCount" {
  type = number
  default = 2

  validation {
    condition = var.subnetsCount >= 2 && var.subnetsCount <= 4
    error_message = "Variable subnetsCount should be between 2 and 4."
  }
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "VPC for the app"
  }
}

// Create Internet Gateway
// Allows communication between your VPC and the public internet.
resource "aws_internet_gateway" "clientInternetGateway" {
  vpc_id = aws_vpc.vpc.id
}

variable "avZoneList" {
  default = [ "1a", "1b", "1c", "1d"]
}
// Create Subnets
resource "aws_subnet" "publicSubnets" {
  count = var.subnetsCount

  vpc_id     = aws_vpc.vpc.id

  cidr_block = "10.0.${count.index}.0/24"
  availability_zone = "us-east-${var.avZoneList[count.index]}"

  tags = {
    Name = "Public Subnet us-east-${var.avZoneList[count.index]}"
  }
}

// Create Custom Route Table
// Determines where network traffic from your subnet or gateway is directed.
resource "aws_route_table" "clientRouteTable" {
  vpc_id = aws_vpc.vpc.id

  // All IPv4 traffic should be directed to through the defined Int.Gateway
  route {
    cidr_block = local.allIps
    gateway_id = aws_internet_gateway.clientInternetGateway.id
  }

  // All IPv6 traffic should be directed through the defined Int.Gateway
  route {
    ipv6_cidr_block = local.allIpsV6
    gateway_id = aws_internet_gateway.clientInternetGateway.id
  }

  tags = {
    Name = "Client Route Table"
  }
}

// Associate Subnet with Route table
// To make a subnet public add a route in our subnet's route table to an Int.Gateway
resource "aws_route_table_association" "routeTableAssociation1a" {
  count = var.subnetsCount
  subnet_id = aws_subnet.publicSubnets[count.index].id
  route_table_id = aws_route_table.clientRouteTable.id
}

output "vpcId" {
  value = aws_vpc.vpc.id
}

output "publicSubnetIds" {
  value = aws_subnet.publicSubnets.*.id
}
