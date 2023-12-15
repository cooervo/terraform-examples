resource "aws_vpc" "main" {
  tags = { Name = "main" }

  cidr_block = var.aws_cidr

  enable_dns_hostnames = true
  enable_dns_support   = true
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "main" {
  count = 3
  tags  = { Name = "subnet-${count.index}" }

  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 3, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  vpc_id            = aws_vpc.main.id
}

# An Internet Gateway resource allows the VPC to connect to the Internet
resource "aws_internet_gateway" "vpc_internet_gateway" {
  vpc_id = aws_vpc.main.id
}
