terraform {
  backend "s3" {
    region         = "eu-west-2"
    profile        ="adm_rhook_cli"
    dynamodb_table = "terraform-vpc-test-state-lock"
    bucket         = "terraform-vpc-test-state-????"
    key            = "terraform-vpc-test/platform-scripts"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:eu-west-2:????:key/???"
  }
}
