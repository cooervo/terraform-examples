provider "aws" {
  region = "us-east-1"
}

module "db" {
  source = "./db"
  server_names = ["mariaDB", "mySQL", "postgres"]
}

output "private_ips" {
  value = module.db.PrivateIp
}
