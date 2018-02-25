terraform {
  backend "s3" {
    region         = "eu-west-2"
    profile        = "adm_rhook_cli"
    dynamodb_table = "terraform-vpc-test-state-lock"
    bucket         = "terraform-vpc-test-state20180223172027722200000001"
    key            = "terraform-vpc-test/platform-scripts"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:eu-west-2:889199313043:key/88789a69-8213-432f-98aa-13ae48acec86"
  }
}
