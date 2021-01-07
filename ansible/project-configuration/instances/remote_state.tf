terraform {
  backend "s3" {
    bucket  = "remote-state-opsschool-tf"
    key     = "project" 
    region  = "us-east-1"
    profile = "reut"
  }
}