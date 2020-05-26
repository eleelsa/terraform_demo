variable "public_key_file" {}

resource "aws_key_pair" "this" {
  key_name   = "ec2_key"
  public_key = file(var.public_key_file)
}
