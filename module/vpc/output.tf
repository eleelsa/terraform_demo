output "vpc_id" {
  value = aws_vpc.this.id
}

output "aws_public_route_table_id" {
  value = aws_route_table.public.id
}

output "public_subnet_all_map" {
  value = aws_subnet.public
}

output "private_subnet_all_map" {
  value = aws_subnet.private
}

output "nat_all_map" {
  value = aws_nat_gateway.this
}

output "create_nat_subnets" {
  value = var.create_nat_subnets
}

output "private_subnets_and_zones" {
  value = var.private_subnets_and_zones 
}
