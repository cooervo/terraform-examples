resource "aws_vpc" "networkVpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "VPC for the app"
  }
}

// Create Internet Gateway
// Allows communication between your VPC and the public internet.
resource "aws_internet_gateway" "clientInternetGateway" {
  vpc_id = aws_vpc.networkVpc.id
}

// 3. Create Subnets
resource "aws_subnet" "publicSubnet1a" {
  vpc_id     = aws_vpc.networkVpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Public Subnet us-east-1a"
  }
}

resource "aws_subnet" "publicSubnet1b" {
  vpc_id     = aws_vpc.networkVpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Public Subnet us-east-1b"
  }
}

// Create Custom Route Table
// Determines where network traffic from your subnet or gateway is directed.
resource "aws_route_table" "clientRouteTable" {
  vpc_id = aws_vpc.networkVpc.id

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

// Associate Subnet with Route table
// To make a subnet public add a route in our subnet's route table to an Int.Gateway
resource "aws_route_table_association" "routeTableAssociation1a" {
  subnet_id = aws_subnet.publicSubnet1a.id
  route_table_id = aws_route_table.clientRouteTable.id
}

resource "aws_route_table_association" "routeTableAssociation1b" {
  subnet_id = aws_subnet.publicSubnet1b.id
  route_table_id = aws_route_table.clientRouteTable.id
}

output "networkVpcId" {
  value = aws_vpc.networkVpc.id
}

output "publicSubnetAId" {
  value = aws_subnet.publicSubnet1a.id
}

output "publicSubnetBId" {
  value = aws_subnet.publicSubnet1b.id
}
