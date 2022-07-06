resource "aws_security_group" "webserverSG" {
  name        = "Web Server Sec Group"
  description = "Accept HTTP and SSH Traffic"
  vpc_id       = var.vpc_id

  // To Allow Port 80 Transport
  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  // To Allow Port 80 Transport
  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  // To Allow Port 80 Transport
  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "tf_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_instance" "Roman-Numerals" {
  ami                    = data.aws_ami.tf_ami.id
  key_name               = var.keyname
  vpc_security_group_ids = [aws_security_group.webserverSG.id]
  user_data              = file("./post_configuration.sh")
  instance_type = "t2.micro"
  tags = {
    "Name" = "Roman Numerals"
  }
}