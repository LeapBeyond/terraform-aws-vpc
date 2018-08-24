terraform {
  backend "s3" {
    region         = "eu-west-2"
    profile        = "adm_rhook_cli"
    dynamodb_table = "terraform-vpc-test-state-lock"
    bucket         = "terraform-vpc-test-state20180824111747816500000001"
    key            = "terraform-vpc-test/platform-scripts"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:eu-west-2:889199313043:key/58cbf7b4-b904-4112-a6fe-c95539f03dc0"
  }
}
