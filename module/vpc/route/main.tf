variable "vpc_id" {}
variable "cidr_block" {}
variable "tg_id" {}
variable "route_name" {}
variable "subnet_and_private_subnet_all_map" {}
variable "subnet_and_nat_all_map" {}

resource "aws_route_table" "this" {
  vpc_id = var.vpc_id
  tags = {
    Name = var.route_name
  }
}

resource "aws_route" "nat" {
  for_each = var.subnet_and_nat_all_map
  route_table_id         = aws_route_table.this.id
  nat_gateway_id = lookup(each.value,each.key).id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "tg" {
  route_table_id         = aws_route_table.this.id
  transit_gateway_id = var.tg_id
  destination_cidr_block = var.cidr_block
}

resource "aws_route_table_association" "this" {
  for_each = var.subnet_and_private_subnet_all_map
  subnet_id      = lookup(each.value,each.key).id
  route_table_id = aws_route_table.this.id
}

