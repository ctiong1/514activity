# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# (Optional) limit SSH to your IP instead of 0.0.0.0/0
variable "ssh_cidr" {
  type        = string
  description = "CIDR allowed for SSH"
  default     = "0.0.0.0/0" # <-- replace with your_ip/32 when ready
}

# Default VPC (change if you use a custom one)
data "aws_vpc" "default" {
  default = true
}

locals {
  aws_key = "CT_AWS_KEY1"
}

resource "aws_security_group" "web" {
  name        = "tf-wp-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = data.aws_vpc.default.id

  # Make deletions more reliable
  revoke_rules_on_delete = true
  timeouts {
    delete = "10m"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
    description = "ssh"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "http"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "my_server" {
  ami                    = data.aws_ami.amazonlinux.id
  instance_type          = var.instance_type
  key_name               = local.aws_key
  user_data              = file("${path.module}/wp_install.sh")
  vpc_security_group_ids = [aws_security_group.web.id]

  tags = { Name = "my ec2" }
}
