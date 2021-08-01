/*terraform {
  required_version = ">= 0.12, < 0.13"
}*/

provider "aws" {
  region = "us-east-1"
}

module "network" {
  source = "./network"
}

module "loadBalancer" {
  source = "./load-balancer"

  subnetIds = [
    module.network.publicSubnetAId,
    module.network.publicSubnetBId
  ]
  networkVpcId = module.network.networkVpcId

  depends_on = [module.network]
}

