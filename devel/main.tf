variable "access_key" {}
variable "secret_key" {}
variable "region" {}
variable "windows_admin_password" {}

provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

#################################
### vpc,subnet,nat(in public) ###
#################################
module "vpc1" {
  source = "../module/vpc"

  vpc_name                = "tfVPC1"
  internet_gateway_name   = "tfGW1"
  public_route_table_name = "tfvpc1_public"
  cidr                    = "10.0.0.0/16"

  public_subnets_name = "tfvpc1_public"
  public_subnets_and_zones = {
    "10.0.0.0/24" = "ap-northeast-1a"
    "10.0.1.0/24" = "ap-northeast-1a"
    "10.0.2.0/24" = "ap-northeast-1a"
  }

  private_subnets_name = "tfvpc1_private"
  private_subnets_and_zones = {
    "10.0.10.0/24" = "ap-northeast-1a"
    "10.0.11.0/24" = "ap-northeast-1a"
    "10.0.12.0/24" = "ap-northeast-1a"
  }

  nat_gateway_name = "tfnat1"
  create_nat_subnets = [
    "10.0.0.0/24",
  ]
}

module "vpc2" {
  source = "../module/vpc"

  vpc_name                = "tfVPC2"
  internet_gateway_name   = "tfGW2"
  public_route_table_name = "tfvpc2_public"
  cidr                    = "10.1.0.0/16"

  public_subnets_name = "tfvpc2_public"
  public_subnets_and_zones = {
    "10.1.0.0/24" = "ap-northeast-1a"
    "10.1.1.0/24" = "ap-northeast-1a"
    "10.1.2.0/24" = "ap-northeast-1a"
  }

  private_subnets_name = "tfvpc2_private"
  private_subnets_and_zones = {
    "10.1.10.0/24" = "ap-northeast-1a"
    "10.1.11.0/24" = "ap-northeast-1a"
    "10.1.12.0/24" = "ap-northeast-1a"
  }

  nat_gateway_name = "tfnat2"
  create_nat_subnets = [
    "10.1.0.0/24",
  ]
}

#######################
### transit_gateway ###
#######################
module "tg" {
  source = "../module/vpc/tg"

  tg_name             = "tfTG"
  tg_route_table_name = "tfroute"
  attach_name         = "tfattach"

  create_subnet_and_public_subnet_all_map = {
    "10.0.0.0/24" = module.vpc1.public_subnet_all_map
    "10.1.0.0/24" = module.vpc2.public_subnet_all_map
  }

  destination_cidr_blocks_and_vpc_route_table_ids = {
    "10.1.0.0/16" = module.vpc1.aws_public_route_table_id
    "10.0.0.0/16" = module.vpc2.aws_public_route_table_id
  }
}

###################################
### route_table(to nat & to tg) ###
###################################
module "vpc1-route" {
  source     = "../module/vpc/route/"
  route_name = "tfvpc1_private"
  vpc_id     = module.vpc1.vpc_id
  tg_id      = module.tg.tg_id
  cidr_block = "10.1.0.0/16"
  subnet_and_private_subnet_all_map = {
    "10.0.10.0/24" = module.vpc1.private_subnet_all_map
    "10.0.11.0/24" = module.vpc1.private_subnet_all_map
    "10.0.12.0/24" = module.vpc1.private_subnet_all_map
  }
  subnet_and_nat_all_map    = {
    "10.0.0.0/24" = module.vpc1.nat_all_map
  }
}

module "vpc2-route" {
  source     = "../module/vpc/route/"
  route_name = "tfvpc2_private"
  vpc_id     = module.vpc2.vpc_id
  tg_id      = module.tg.tg_id
  cidr_block = "10.0.0.0/16"
  subnet_and_private_subnet_all_map = {
    "10.1.10.0/24" = module.vpc2.private_subnet_all_map
    "10.1.11.0/24" = module.vpc2.private_subnet_all_map
    "10.1.12.0/24" = module.vpc2.private_subnet_all_map
  }
  subnet_and_nat_all_map    = {
    "10.1.0.0/24" = module.vpc2.nat_all_map
  }
}

###########
### ec2 ###
###########
data "template_file" "rh8" {
  template = file("./scripts/rh8.sh.tpl")
}
data "template_file" "linux_common" {
  template = file("./scripts/linux_common.sh.tpl")
}

data "template_file" "win2019" {
  template = file("./scripts/ConfigureRemotingForAnsible.ps1.tpl")
  vars = {
    admin_password = var.windows_admin_password
  }
}

module "pub_key" {
  source          = "../module/ec2/key/"
  public_key_file = "./ec2_key.pub"
}

module "vpc1_sg" {
  source = "../module/ec2/sg/"

  vpc_id  = module.vpc1.vpc_id
  sg_name = "common"
  ingress_port = [
    "22",
    "2049",
    "3389",
    "5986",
  ]
  ingress_cidr_blocks = "0.0.0.0/0"
  ingress_icmp_enable = true
  egress_from_port    = 0
  egress_to_port      = 65535
  egress_cidr_blocks  = "0.0.0.0/0"
  egress_icmp_enable  = true
}

module "vpc1_pulic1_ec2" {
  source = "../module/ec2"

  ami           = "ami-07dd14faa8a17fb3e"
  instance_type = "t2.micro"
  public_key_id = module.pub_key.key_id
  subnet_id     = lookup(module.vpc1.public_subnet_all_map,"10.0.0.0/24").id
  private_ips = [
    "10.0.0.10",
  ]
  instance_name               = "vpc1_rh8"
  user_data_file              = data.template_file.rh8
  sg_id                       = module.vpc1_sg.sg_id
  associate_public_ip_address = true
}

module "vpc1_private1_ec2" {
  source = "../module/ec2"

  ami           = "ami-008755994dfc325f7"
  instance_type = "t2.micro"
  public_key_id = module.pub_key.key_id
  subnet_id     = lookup(module.vpc1.private_subnet_all_map,"10.0.10.0/24").id
  private_ips = [
    "10.0.10.10",
  ]
  instance_name               = "vpc1_win2019"
  user_data_file              = data.template_file.win2019
  sg_id                       = module.vpc1_sg.sg_id
  associate_public_ip_address = false
}

module "vpc1_private2_ec2" {
  source = "../module/ec2"

  ami           = "ami-0f310fced6141e627"
  instance_type = "t2.micro"
  public_key_id = module.pub_key.key_id
  subnet_id     = lookup(module.vpc1.private_subnet_all_map,"10.0.11.0/24").id
  private_ips = [
    "10.0.11.10",
  ]
  instance_name               = "vpc1_AM2"
  user_data_file              = data.template_file.linux_common
  sg_id                       = module.vpc1_sg.sg_id
  associate_public_ip_address = false
}

### vpc2
module "vpc2_sg" {
  source = "../module/ec2/sg/"

  vpc_id  = module.vpc2.vpc_id
  sg_name = "common"
  ingress_port = [
    "22",
    "2049",
    "3389",
    "5986",
  ]
  ingress_cidr_blocks = "0.0.0.0/0"
  ingress_icmp_enable = true
  egress_from_port    = 0
  egress_to_port      = 65535
  egress_cidr_blocks  = "0.0.0.0/0"
  egress_icmp_enable  = true
}

module "vpc2_pulic1_ec2" {
  source = "../module/ec2"

  ami           = "ami-07dd14faa8a17fb3e"
  instance_type = "t2.micro"
  public_key_id = module.pub_key.key_id
  subnet_id     = lookup(module.vpc2.public_subnet_all_map,"10.1.0.0/24").id
  private_ips = [
    "10.1.0.10",
  ]
  instance_name               = "vpc2_rh8"
  user_data_file              = data.template_file.linux_common
  sg_id                       = module.vpc2_sg.sg_id
  associate_public_ip_address = true
}

module "vpc2_private1_ec2" {
  source = "../module/ec2"

  ami           = "ami-008755994dfc325f7"
  instance_type = "t2.micro"
  public_key_id = module.pub_key.key_id
  subnet_id     = lookup(module.vpc2.private_subnet_all_map,"10.1.10.0/24").id
  private_ips = [
    "10.1.10.10",
  ]
  instance_name               = "vpc2_win2019"
  user_data_file              = data.template_file.win2019
  sg_id                       = module.vpc2_sg.sg_id
  associate_public_ip_address = false
}

module "vpc2_private2_ec2" {
  source = "../module/ec2"

  ami           = "ami-0f310fced6141e627"
  instance_type = "t2.micro"
  public_key_id = module.pub_key.key_id
  subnet_id     = lookup(module.vpc2.private_subnet_all_map,"10.1.11.0/24").id
  private_ips = [
    "10.1.11.10",
  ]
  instance_name               = "vpc2_AM2"
  user_data_file              = data.template_file.linux_common
  sg_id                       = module.vpc2_sg.sg_id
  associate_public_ip_address = false
}
