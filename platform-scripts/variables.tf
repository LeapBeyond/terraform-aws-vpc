variable "tags" {
  default = {
    "owner"   = "rahook"
    "project" = "vpc-test"
    "client"  = "Internal"
  }
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

/* variables to inject via terraform.tfvars */

variable "aws_account_id" {}
variable "aws_profile" {}
variable "aws_region" {}

variable "protected_key" {}
variable "bastion_key" {}

variable "ssh_inbound" {
  type = "list"
}
