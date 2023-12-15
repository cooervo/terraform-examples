variable "availabilityZoneInput" {
  type = string
}

variable "clientNetworkInterfaceId" {
  type = string
}

resource "aws_instance" "clientServer" {
  ami = "ami-0747bdcabd34c712a" // free tier ubuntu AMI
  instance_type = "t2.micro"
  availability_zone = var.availabilityZoneInput

  // allows us to securely SSH into our instance
  key_name = "ec2-key-pairs"

  network_interface {
    device_index = 0
    network_interface_id = var.clientNetworkInterfaceId
  }

  user_data = <<-EOF
            #!/bin/bash
            sudo apt update -y
            sudo apt install apache2 -y
            sudo systemctl start apache2
            sudo bash -c 'echo ClientServer running on Availability Zone: ${var.availabilityZoneInput} > /var/www/html/index.html'
            EOF
  tags = {
    Name = "Client Server"
  }
}
