variable "sgAllowHttpAndHttpsId" {
  type = string
}

resource "aws_launch_template" "clientServer" {
  image_id = "ami-0747bdcabd34c712a" //TODO use local var
  instance_type = "t2.micro"

  vpc_security_group_ids = [var.sgAllowHttpAndHttpsId]

  user_data = filebase64("${path.module}/user_data.sh")

  lifecycle {
    create_before_destroy = true
  }
}

output "clientServer" {
  value = aws_launch_template.clientServer
}
