provider "aws" {
  region = "us-east-1"
}

variable "vpcName" {
  type = string
  default = "vpc-example"
}

// Will ask user for name of the vpc via terminal input
variable "vpcInputName" {
  type = string
  description = "Set the name of the VPC via input"
}

/*
 Creates a VPC with a range of 65,536
 possible IPs
 Host Address Range: 10.0.0.1  -  10.0.255.254
 more at: https://www.site24x7.com/tools/ipv4-subnetcalculator.html
*/
resource "aws_vpc" "vpc_example" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = var.vpcInputName
  }
}

// Will print the id of VPC "vpc_example"
output "vpcId" {
  value = aws_vpc.vpc_example.id
}
