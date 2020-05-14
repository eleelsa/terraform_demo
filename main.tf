variable "access_key" {}
variable "secret_key" {}
variable "region" {}
variable "admin_password" {}
variable "user_data_path" {}

provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}
