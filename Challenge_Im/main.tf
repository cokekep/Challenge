provider "aws" {
  region     = "eu-central-1"
  profile = var.profile
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu-18_04" {
  most_recent = true
  owners = ["${var.ubuntu_account_number}"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}
# create VPC
resource "aws_vpc" "im-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "dev"
  }
}

# create internet Gateway
resource "aws_internet_gateway" "im-gateway" {
   vpc_id = aws_vpc.im-vpc.id
}

# create custom route table assocaite to IG for routable subnet
resource "aws_route_table" "dev-pub-route-table" {
  vpc_id = aws_vpc.im-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.im-gateway.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.im-gateway.id
  }

  tags = {
    Name = "dev"
  }
}

# create route table for non-routable subnet
resource "aws_route_table" "dev-priv-route-table" {
  vpc_id = aws_vpc.im-vpc.id

  tags = {
    Name = "dev"
  }
}

# create the public subnets
resource "aws_subnet" "public-subnet-1" {
  vpc_id            = aws_vpc.im-vpc.id
  cidr_block        = var.subnet_prefix[0].cidr_block
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = var.subnet_prefix[0].name
  }
}

resource "aws_subnet" "public-subnet-2" {
  vpc_id            = aws_vpc.im-vpc.id
  cidr_block        = var.subnet_prefix[1].cidr_block
  availability_zone = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = var.subnet_prefix[1].name
  }
}

resource "aws_subnet" "public-subnet-3" {
  vpc_id            = aws_vpc.im-vpc.id
  cidr_block        = var.subnet_prefix[2].cidr_block
  availability_zone = data.aws_availability_zones.available.names[2]
  map_public_ip_on_launch = true

  tags = {
    Name = var.subnet_prefix[2].name
  }
}

# private subnets
resource "aws_subnet" "private-subnet-1" {
  vpc_id            = aws_vpc.im-vpc.id
  cidr_block        = var.subnet_prefix[3].cidr_block
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = var.subnet_prefix[3].name
  }
}

resource "aws_subnet" "private-subnet-2" {
  vpc_id            = aws_vpc.im-vpc.id
  cidr_block        = var.subnet_prefix[4].cidr_block
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = var.subnet_prefix[4].name
  }
}

resource "aws_subnet" "private-subnet-3" {
  vpc_id            = aws_vpc.im-vpc.id
  cidr_block        = var.subnet_prefix[5].cidr_block
  availability_zone = data.aws_availability_zones.available.names[2]

  tags = {
    Name = var.subnet_prefix[5].name
  }
}

# Associate public subnet 1 to 3 with Route Table
resource "aws_route_table_association" "im-pub-ass-route-1" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.dev-pub-route-table.id
}

resource "aws_route_table_association" "im-pub-ass-route-2" {
  subnet_id      = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.dev-pub-route-table.id
}

resource "aws_route_table_association" "im-pub-ass-route-3" {
  subnet_id      = aws_subnet.public-subnet-3.id
  route_table_id = aws_route_table.dev-pub-route-table.id
}

# associate private subnet 3 to 6 with Route Table
resource "aws_route_table_association" "im-priv-ass-route-1" {
  subnet_id      = aws_subnet.private-subnet-1.id
  route_table_id = aws_route_table.dev-priv-route-table.id
}

resource "aws_route_table_association" "im-priv-ass-route-2" {
  subnet_id      = aws_subnet.private-subnet-2.id
  route_table_id = aws_route_table.dev-priv-route-table.id
}

resource "aws_route_table_association" "im-priv-ass-route-3" {
  subnet_id      = aws_subnet.private-subnet-3.id
  route_table_id = aws_route_table.dev-priv-route-table.id
}

# Security group ec2 in Asg to allow port, 80, 443 only request from ALB
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.im-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.im-alb-sg.id]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.im-alb-sg.id]
  }
  ingress {
    description = "SSH"
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

  tags = {
    Name = "allow_web"
  }
}

# security group for ALB
resource "aws_security_group" "im-alb-sg" {
  name        = "allow_alb_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.im-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

#launch template

resource "aws_launch_template" "im-template" {
  name_prefix   = "im-template"
  image_id      = data.aws_ami.ubuntu-18_04.id
  instance_type = "t2.micro"
  user_data = filebase64("${path.module}/user_data.sh")
  vpc_security_group_ids = [aws_security_group.allow_web.id]

}

# Asg
resource "aws_autoscaling_group" "im-asg" {

  vpc_zone_identifier = [
    aws_subnet.public-subnet-1.id,
    aws_subnet.public-subnet-2.id,
    aws_subnet.public-subnet-3.id
  ]
 
  desired_capacity   = 3
  max_size           = 5
  min_size           = 2

  target_group_arns = [aws_lb_target_group.im-tg.id]

  launch_template {
    id      = aws_launch_template.im-template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "im-asg"
    propagate_at_launch = true
  }
}

# ALB
resource "aws_lb" "im-alb" {
  name               = "im-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.im-alb-sg.id]
  subnets            = [
    aws_subnet.public-subnet-1.id,
    aws_subnet.public-subnet-2.id,
    aws_subnet.public-subnet-3.id
  ]

  enable_deletion_protection = true
}
# target group
resource "aws_lb_target_group" "im-tg" {
  name        = "im-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id   = aws_vpc.im-vpc.id
}

# # ALB listener for HTTPS
# resource "aws_lb_listener" "im-https-listener" {
#   load_balancer_arn = aws_lb.im-alb.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.im-tg.arn
#   }
# }

# ALB listener for HTTP
resource "aws_lb_listener" "im-http-listener" {
  load_balancer_arn = aws_lb.im-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.im-tg.arn
  }
}

resource "aws_iam_instance_profile" "cron-runner-profile" {
  name = "test_profile"
  role = aws_iam_role.cron-runner-role.name
}

resource "aws_iam_role" "cron-runner-role" {
  name = "cron-runner-role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "cron-runner-policy" {
  name        = "cron-runner-policy"
  description = "Policy for "

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "autoscaling:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cron-runner-attachment" {
  role       = aws_iam_role.cron-runner-role.name
  policy_arn = aws_iam_policy.cron-runner-policy.arn
}

resource "aws_instance" "cron-runner" {
  ami           = data.aws_ami.ubuntu-18_04.id
  instance_type = "t2.micro"
  user_data = filebase64("${path.module}/user_data_cron.sh")
  iam_instance_profile = aws_iam_instance_profile.cron-runner-profile.name
  associate_public_ip_address = true
  subnet_id = aws_subnet.public-subnet-1.id
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  key_name      = aws_key_pair.generated_key.key_name
}

resource "tls_private_key" "im-private-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.im-private-key.public_key_openssh
}