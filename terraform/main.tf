provider "aws" {
   region = "eu-central-1"
}

resource "aws_vpc" "my-vpc" {

  cidr_block = "10.161.0.0/24"

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}
resource "aws_subnet" "my-subnet-a" {

  vpc_id = aws_vpc.my-vpc.id
  cidr_block = "10.161.0.0/25"
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = true 
  tags = {
    Environment = "dev"
  }
}
resource "aws_subnet" "my-subnet-b" {


  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.161.0.128/26"
  availability_zone = "eu-central-1b"
  map_public_ip_on_launch = true 

  tags = {
    Environment = "dev"
  }
}
resource "aws_subnet" "my-subnet-c" {


  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.161.0.192/26"
  availability_zone = "eu-central-1c"
  map_public_ip_on_launch = true

  tags = {
    Environment = "dev"
  }
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

resource "aws_route_table_association" "rta-a"{
    subnet_id = aws_subnet.my-subnet-a.id
    route_table_id = aws_route_table.my-route-table.id
}

resource "aws_route_table_association" "rta-b"{
    subnet_id = aws_subnet.my-subnet-b.id
    route_table_id = aws_route_table.my-route-table.id
}

resource "aws_route_table_association" "rta-c"{
    subnet_id = aws_subnet.my-subnet-c.id
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
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_instance" "nginx1" {
  
  ami = "ami-06ec8443c2a35b0ba"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name 
  subnet_id = aws_subnet.my-subnet-a.id
  vpc_security_group_ids = [ aws_security_group.generic-sg.id ]
  key_name = "dev-key"

}

resource "aws_instance" "nginx2" {

  ami = "ami-06ec8443c2a35b0ba"
  instance_type = "t2.micro"

  subnet_id = aws_subnet.my-subnet-b.id
  vpc_security_group_ids = [ aws_security_group.generic-sg.id ]
  key_name = "dev-key"

}
resource "aws_instance" "nginx3" {

  ami = "ami-06ec8443c2a35b0ba"
  instance_type = "t2.micro"

  subnet_id = aws_subnet.my-subnet-c.id
  vpc_security_group_ids = [ aws_security_group.generic-sg.id ]
  key_name = "dev-key"

}


module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = "my-alb"

  load_balancer_type = "application"

  vpc_id             = aws_vpc.my-vpc.id
  subnets            = [aws_subnet.my-subnet-c.id, aws_subnet.my-subnet-b.id, aws_subnet.my-subnet-a.id]
  security_groups    = [aws_security_group.generic-sg.id]


  target_groups = [
    {
      name_prefix      = "pref-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      targets = [
        {
          target_id = aws_instance.nginx3.id
          port = 80
        },
        {
          target_id = aws_instance.nginx2.id
          port = 80
        },
        {
          target_id = aws_instance.nginx1.id
          port = 80
        }
      ]
    }
  ]
  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = "dev"
  }
}
