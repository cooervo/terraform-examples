provider "aws" {
  region = "us-east-1"
}

module "ec2module" {
  source = "./ec2-module"
  ec2_name = "Example module name"
}

output "module_instance_id" {
  value = module.ec2module.instance_id
}
