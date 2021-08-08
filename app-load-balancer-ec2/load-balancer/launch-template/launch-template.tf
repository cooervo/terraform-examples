variable "secGroupAllowHttpAndHttpsId" {
  type = string
}

locals  {
  ubuntuAmiId = "ami-0747bdcabd34c712a"
}

resource "aws_launch_template" "clientServer" {
  name = "clientServer"
  image_id = local.ubuntuAmiId
  instance_type = "t2.micro"

  vpc_security_group_ids = [var.secGroupAllowHttpAndHttpsId]

  user_data = filebase64("${path.module}/user_data.sh")

  lifecycle {
    create_before_destroy = true
  }
}

output "clientServer" {
  value = aws_launch_template.clientServer
}
