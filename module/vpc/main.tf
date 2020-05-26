variable "cidr" {}
variable "vpc_name" {}
variable "public_subnets_and_zones" {}
variable "public_subnets_name" {}
variable "private_subnets_and_zones" {}
variable "private_subnets_name" {}
variable "public_route_table_name" {}
variable "internet_gateway_name" {}
variable "create_nat_subnets" {}
variable "nat_gateway_name" {}

####################
#### vpc common ####
####################
resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_default_route_table" "this" {
  default_route_table_id = aws_vpc.this.default_route_table_id
  tags = {
    Name = format("%s_default",var.vpc_name)
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = var.internet_gateway_name
  }
}

#######################
#### public subnet ####
#######################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = var.public_route_table_name
  }
}

resource "aws_route" "global" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.this.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_subnet" "public" {
  for_each = var.public_subnets_and_zones
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.key
  availability_zone       = each.value
  map_public_ip_on_launch = true
  tags = {
    Name = format("%s[%s]",var.public_subnets_name,each.key)
  }
}

resource "aws_eip" "this" {
  for_each = toset(var.create_nat_subnets)
  vpc = true
  tags = {
    Name = format("%s[%s]",var.nat_gateway_name,each.key)
  }
}

resource "aws_nat_gateway" "this" {
  for_each = toset(var.create_nat_subnets)
  allocation_id = aws_eip.this[each.key].id
  subnet_id     = aws_subnet.public[each.key].id
  tags = {
    Name = format("%s[%s]",var.nat_gateway_name,each.key)
  }
  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table_association" "public" {
  for_each = var.public_subnets_and_zones
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

########################
#### private subnet ####
########################
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.this.id
  for_each = var.private_subnets_and_zones
  cidr_block              = each.key
  availability_zone       = each.value
  map_public_ip_on_launch = false

  tags = {
    Name = format("%s[%s]",var.private_subnets_name,each.key)
  }
}
