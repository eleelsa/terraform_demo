variable "ami" {}
variable "instance_type" {}
variable "public_key_id" {}
variable "subnet_id" {}
variable "private_ips" {}
variable "instance_name" {}
variable "user_data_file" {}
variable "sg_id" {}
variable "associate_public_ip_address" {}

resource "aws_instance" "this" {
  for_each = toset(var.private_ips)
  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = var.public_key_id
  vpc_security_group_ids      = [var.sg_id]
  subnet_id                   = var.subnet_id
  private_ip                  = each.key
  associate_public_ip_address = var.associate_public_ip_address

  user_data = var.user_data_file != "" ? var.user_data_file.rendered : ""

  tags = {
    Name = format("%s[%s]",var.instance_name,each.key)
  }
}
