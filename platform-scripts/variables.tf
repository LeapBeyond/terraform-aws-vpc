variable "tags" {
  default = {
    "owner"   = "rahook"
    "project" = "vpc-test"
    "client"  = "Internal"
  }
}

variable "ami_name" {
  default = "amzn2-ami-hvm-2017.12.0.20180115-x86_64-gp2"
}

variable "root_vol_size" {
  default = 8
}

variable "bastion_user" {
  default = "ec2-user"
}

variable "instance_type" {
  default = "t2.micro"
}

# 172.21.0.0 - 172.21.255.255
variable "test_vpc_cidr" {
  default = "172.21.0.0/16"
}

variable "bastion_subnet_cidr" {
  default = "172.21.10.0/24"
}

variable "protected_subnet_cidr" {
  default = "172.21.20.0/24"
}

# internal ip of the NAT gateway
variable "eip_nat_ip" {
  default = "172.21.10.50"
}

# variables to inject via terraform.tfvars or environment

variable "aws_account_id" {}
variable "aws_profile" {}
variable "aws_region" {}

variable "protected_key" {}
variable "bastion_key" {}

variable "ssh_inbound" {
  type = "list"
}
