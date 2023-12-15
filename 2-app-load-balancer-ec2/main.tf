terraform {
  required_version = "~>1.0.2"
}

provider "aws" {
  region = "us-east-1"
}

module "network" {
  source = "./network"
  subnetsCount = 2
}

module "loadBalancer" {
  source = "./load-balancer"

  subnetIds = module.network.publicSubnetIds
  vpcId = module.network.vpcId
}

output "albDnsName" {
  value = module.loadBalancer.albDnsName
}

