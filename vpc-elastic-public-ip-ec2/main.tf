provider "aws" {
  region = "us-east-1"
}

locals {
  availabilityZoneA = "us-east-1a"
}

module "clientNetworkModule" {
  source = "./network"

  availabilityZoneInput = local.availabilityZoneA
}

module "clientServerModule" {
  source = "./client-server"

  availabilityZoneInput = local.availabilityZoneA
  clientNetworkInterfaceId = module.clientNetworkModule.clientNetworkInterfaceId
}
