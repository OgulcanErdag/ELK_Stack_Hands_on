terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "al2023" {
  most_recent      = true
  owners           = ["amazon"]

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name = "name"
    values = ["al2023-ami-2023*"]
  }
  filter {
    name = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "elk" {
  ami = data.aws_ami.al2023.id
  instance_type = "t2.micro"
  key_name = "serag"
  vpc_security_group_ids = [aws_security_group.elk-sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2-profile.name
  tags = {
    Name = "elk-server"
  }
}

resource "aws_iam_role" "aws_access" {
  name = "awsrole-elk"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aws_access_policy" {
  role       = aws_iam_role.aws_access.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "ec2-profile" {
  name = "elk-server-profile"
  role = aws_iam_role.aws_access.name
}


resource "aws_security_group" "elk-sg" {
  name = "elk-in-eks-sec-gr"
  tags = {
    Name = "elk-in-eks-sec-gr"
  }

  ingress {
    from_port = 22
    protocol  = "tcp"
    to_port   = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "elk-server-DNS" {
  value = aws_instance.elk.public_ip
}