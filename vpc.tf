resource "aws_vpc" "tfVPC01" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = "true"
  enable_dns_hostnames = "false"
  tags = {
    Name = "tfVPC01"
  }
}

resource "aws_internet_gateway" "tfGW" {
  vpc_id = aws_vpc.tfVPC01.id
}

resource "aws_eip" "tfnat" {
  vpc = true
  tags = {
    Name = "tfnat"
  }
}

resource "aws_subnet" "tfpublic-a" {
  vpc_id = aws_vpc.tfVPC01.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-northeast-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "tfpublic-a"
  }
}
resource "aws_route_table" "tfpublic-route" {
  vpc_id = aws_vpc.tfVPC01.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tfGW.id
  }
}
resource "aws_route_table_association" "tfpublic-a" {
  subnet_id = aws_subnet.tfpublic-a.id
  route_table_id = aws_route_table.tfpublic-route.id
}
resource "aws_nat_gateway" "tf_for_private" {
  allocation_id = aws_eip.tfnat.id
  subnet_id     = aws_subnet.tfpublic-a.id
  tags = {
    Name = "tfnat_gateway"
  }
  depends_on = [aws_internet_gateway.tfGW]
}


resource "aws_subnet" "tfprivate-a" {
  vpc_id = aws_vpc.tfVPC01.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "tfprivate-a"
  }
}
resource "aws_route_table" "tfprivate-route-a" {
  vpc_id = aws_vpc.tfVPC01.id
}
resource "aws_route_table_association" "tfprivate-a" {
  subnet_id = aws_subnet.tfprivate-a.id
  route_table_id = aws_route_table.tfprivate-route-a.id
}


resource "aws_subnet" "tfprivate-b" {
  vpc_id = aws_vpc.tfVPC01.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-northeast-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "tfprivate-b"
  }
}
resource "aws_route_table" "tfprivate-route-b" {
  vpc_id = aws_vpc.tfVPC01.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.tf_for_private.id
  }
  tags = {
    Name = "private_subnet_route_table-b"
  }
}
resource "aws_route_table_association" "tfprivate-b" {
  subnet_id = aws_subnet.tfprivate-b.id
  route_table_id = aws_route_table.tfprivate-route-b.id
}


resource "aws_security_group" "tfSG01" {
  name        = "tfadmin"
  description = "Allow specific Any port traffic."
  vpc_id      = aws_vpc.tfVPC01.id
}

resource "aws_security_group_rule" "inbound_SSH" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.tfSG01.id
}

resource "aws_security_group_rule" "inbound_RDP" {
  type = "ingress"
  from_port = 3389
  to_port = 3389
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.tfSG01.id
}

resource "aws_security_group_rule" "inbound_winrm" {
  type = "ingress"
  from_port = 5986
  to_port = 5986
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.tfSG01.id
}

resource "aws_security_group_rule" "inbound_ICMP" {
  type = "ingress"
  from_port = -1
  to_port = -1
  protocol = "icmp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.tfSG01.id
}

resource "aws_security_group_rule" "outbound_ALL" {
  type = "egress"
  from_port = 0
  to_port = 65535
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.tfSG01.id
}

resource "aws_security_group_rule" "outbound_ICMP" {
  type = "egress"
  from_port = -1
  to_port = -1
  protocol = "icmp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.tfSG01.id
}

