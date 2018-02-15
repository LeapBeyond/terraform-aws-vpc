variable "tags" {
  default = {
    "owner"   = "rahook"
    "project" = "vpc-test"
    "client"  = "Internal"
  }
}

variable "bucket_prefix" {
  default = "terraform-vpc-test-state"
}

variable "lock_table_name" {
  default = "terraform-vpc-test-state-lock"
}

/* variables to inject via terraform.tfvars */
variable "aws_region" {}

variable "aws_account_id" {}
variable "aws_profile" {}
