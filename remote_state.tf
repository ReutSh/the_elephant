terraform {
  backend "s3" {
    bucket  = "opsschool-remote-state-terraform"
    key     = "application"
    region  = "us-east-1"
    profile = "ops-school"
  }
}