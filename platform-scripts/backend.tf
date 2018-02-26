terraform {
  backend "s3" {
    region         = "eu-west-2"
    profile        = "adm_rhook_cli"
    dynamodb_table = "terraform-vpc-test-state-lock"
    bucket         = "terraform-vpc-test-state20180226140722169400000001"
    key            = "terraform-vpc-test/platform-scripts"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:eu-west-2:889199313043:key/82c7172c-8084-4beb-9290-a272e563fc5a"
  }
}
