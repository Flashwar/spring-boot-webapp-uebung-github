terraform {
  required_version = ">= 1.0.0" # Ensure that the Terraform version is 1.0.0 or higher

  required_providers {
    aws = {
      source = "hashicorp/aws" # Specify the source of the AWS provider
      version = "~> 4.0"        # Use a version of the AWS provider that is compatible with version
    }
  }
}

provider "aws" {
  region     = var.region
  access_key = var.aws_credentials["access_key"]
  secret_key = var.aws_credentials["secret_key"]
  token      = var.aws_credentials["token"]
}

resource "aws_security_group" "sg_spring_ec2" {
  name = "sg_spring_ec2"
}

resource "aws_security_group_rule" "allow_ssh_traffic_to_ec2" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg_spring_ec2.id
}

# Erlauben Sie http traffic für sg_bottletube_ec2
resource "aws_security_group_rule" "allow_http_traffic_to_ec2" {
  description       = "Allow 8080 inbound traffic"
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg_spring_ec2.id

}

resource "aws_security_group_rule" "allow_all_outbound_traffic_from_ec2" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg_spring_ec2.id
}

resource "aws_instance" "springboot" {
  ami                         = var.ami_ubuntu_2024LTS
  instance_type               = var.instance_type.micro
  key_name                    = var.laptop_linux_keypair
  vpc_security_group_ids      = [aws_security_group.sg_spring_ec2.id]
  associate_public_ip_address = true
  user_data                   = <<-EOF
              #!/bin/bash
              sudo apt update -y && apt-get install docker.io -y
              sudo service docker start
              sudo usermod -aG docker ubuntu
              docker pull flashwar/ccsystemintegrationmavenspring:latest
              docker run --rm -d -p 8080:8080 flashwar/ccsystemintegrationmavenspring:latest
            EOF

}

output "SPRING_EC2_HOST_DNS_NAME" {
  value = aws_instance.springboot.public_dns
}