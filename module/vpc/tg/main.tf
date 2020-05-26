variable "tg_name" {}
variable "tg_route_table_name" {}
variable "attach_name" {}
variable "create_subnet_and_public_subnet_all_map" {}
variable "destination_cidr_blocks_and_vpc_route_table_ids" {}

resource "aws_ec2_transit_gateway" "this" {
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  tags = {
    Name = var.tg_name
  }
}

resource "aws_ec2_transit_gateway_route_table" "this" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  tags = {
    Name = var.tg_route_table_name
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "public" {
  for_each = var.create_subnet_and_public_subnet_all_map
  subnet_ids                                      = [lookup(each.value,each.key).id]
  transit_gateway_id                              = aws_ec2_transit_gateway.this.id
  vpc_id                                          = lookup(each.value,each.key).vpc_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  tags = {
    Name = format("%s", var.attach_name)
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each = var.create_subnet_and_public_subnet_all_map
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.public[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
}
resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each = var.create_subnet_and_public_subnet_all_map
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.public[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
}

resource "aws_route" "to_tg" {
  for_each = var.destination_cidr_blocks_and_vpc_route_table_ids
  route_table_id         = each.value
  transit_gateway_id     = aws_ec2_transit_gateway.this.id
  destination_cidr_block = each.key
}
