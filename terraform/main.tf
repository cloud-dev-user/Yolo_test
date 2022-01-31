provider "aws" {
   region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}
resource "aws_vpc" "my-vpc" {

  cidr_block = var.vpc_range

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_subnet" "eu_subnet" {

    for_each = var.subnet_range
    vpc_id = aws_vpc.my-vpc.id
    cidr_block = each.value.s_cidr_range
    availability_zone = each.value.s_availability_zone
    tags = {
    Name = "${each.key}"
  }
}

data "aws_subnet_ids" "eu_subnet_id" {
  vpc_id = aws_vpc.my-vpc.id

  depends_on = [
    aws_subnet.eu_subnet,
  ]
}

resource "aws_internet_gateway" "my-IGW" {
    vpc_id = aws_vpc.my-vpc.id

    tags = {
        Name = "dev"
    }
}

resource "aws_route_table" "my-route-table" {
    vpc_id = aws_vpc.my-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my-IGW.id
    }

    tags =  {
        Name = "dev-rt"
    }
}

resource "aws_route_table_association" "rta"{
    for_each  = var.subnet_range
    subnet_id = each.key
    route_table_id = aws_route_table.my-route-table.id
}

resource "aws_security_group" "generic-sg" {
    vpc_id = aws_vpc.my-vpc.id

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
   dynamic "ingress" {
    for_each = var.y_ingress

      content {
        from_port = ingress.value.port
        to_port = ingress.value.port
        protocol = ingress.value.protocol
        cidr_blocks = ingress.value.y_cidr_range
    }
}
}

resource "aws_iam_role" "ec2-cloudwatch-role" {
                 name = "ec2-cloudwatch-access"
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
  managed_policy_arns = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"]
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2-cloudwatch-role.name
}

resource "aws_instance" "ec2-instance" {

  for_each =  var.subnet_range
  ami = var.image_id
  instance_type = var.instance_type
  subnet_id = each.key
  vpc_security_group_ids = [ aws_security_group.generic-sg.id ]
  key_name = var.key-id
 tags = { Name = "${each.key}_ec2_instance" }

  depends_on = [
    aws_subnet.eu_subnet,
  ]
}

