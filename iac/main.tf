provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.secret_key
}

resource "tls_private_key" "instance" {
  algorithm = "RSA"
}

resource "aws_key_pair" "instance" {
  key_name   = "instance-keypair"
  public_key = tls_private_key.instance.public_key_openssh
  tags = {
    Name = "instance-keypair"
  }
}

resource "aws_secretsmanager_secret" "ec2_private_key" {
  name = "ec2_private_key"
}

resource "aws_secretsmanager_secret_version" "ec2_private_key" {
  secret_id     = aws_secretsmanager_secret.ec2_private_key.id
  secret_string = tls_private_key.instance.private_key_pem
}

resource "aws_secretsmanager_secret" "ec2_public_key" {
  name = "ec2_public_key"
}

resource "aws_secretsmanager_secret_version" "ec2_public_key" {
  secret_id     = aws_secretsmanager_secret.ec2_public_key.id
  secret_string = tls_private_key.instance.public_key_pem
}

resource "aws_security_group" "default-sg" {
  name        = "sec-grp"
  description = "Allow HTTP and SSH traffic via Terraform"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "webserver" {
  ami                         = "ami-007855ac798b5175e"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.instance.key_name
  vpc_security_group_ids      = [aws_security_group.default-sg.id]
  associate_public_ip_address = true
  user_data                   = file("deploy.sh")
}