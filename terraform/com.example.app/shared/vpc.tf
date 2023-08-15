resource "aws_vpc" "vpc" {
  cidr_block = "172.31.0.0/16"
  tags = {
    Name = "${var.project_name} VPC"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.project_name} IGW"
  }
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public route"
  }
}

resource "aws_subnet" "subnet_c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "172.31.1.0/25"
  availability_zone = "${var.aws_region}c"
  map_public_ip_on_launch = true
  tags              = {
    Name = "${var.project_name}-c"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_c.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "172.31.1.128/25"
  availability_zone = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags              = {
    Name = "${var.project_name}-b"
  }
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_security_group" "instance_sg" {
  name        = "${var.project_name}.instance"
  description = "${var.project_name} - ec2 instance sg"
  vpc_id      = aws_vpc.vpc.id
  tags        = {
    Name = var.project_name
  }
}

resource "aws_security_group_rule" "permit_80_all_ipv4" {
  description       = "Permit TCP 80"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.instance_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_permit_all" {
  description       = "permit talking to anyone"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.instance_sg.id
}