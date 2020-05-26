variable "sg_name" {}
variable "vpc_id" {}
variable "ingress_port" {} 
variable "ingress_cidr_blocks" {}
variable "egress_from_port" {}
variable "egress_to_port" {} 
variable "egress_cidr_blocks" {}
variable "ingress_icmp_enable" {}
variable "egress_icmp_enable" {}

resource "aws_security_group" "this" {
  name        = var.sg_name
  description = "Allow specific Any port traffic."
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "inbound_tcp" {
  for_each = toset(var.ingress_port)
  type              = "ingress"
  from_port         = each.key
  to_port           = each.key
  protocol          = "tcp"
  cidr_blocks       = [var.ingress_cidr_blocks]
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "outbound_tcp" {
  type              = "egress"
  from_port         = var.egress_from_port
  to_port           = var.egress_to_port
  protocol          = "tcp"
  cidr_blocks       = [var.egress_cidr_blocks]
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "inbound_icmp" {
  count = var.ingress_icmp_enable ? 1 : 0
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "outbound_icmp" {
  count = var.egress_icmp_enable ? 1 : 0
  type              = "egress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
}

