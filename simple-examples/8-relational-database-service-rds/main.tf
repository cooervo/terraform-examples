provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "rds-example" {
  name = "dbName"
  identifier = "identifier-example"
  instance_class = "db.t2.micro"
  engine = "mariadb"
  engine_version = "10.2.21"
  port = 3306
  allocated_storage = 20
  skip_final_snapshot = true

  # do not include credentials in prod
  username = "mat"
  password = "passphrasesarebetterthanpasswords"

}
