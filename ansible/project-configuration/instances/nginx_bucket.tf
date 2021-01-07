resource "aws_s3_bucket" "nginx_access_log" {
  bucket = "opsschool-nginx-access-log"
  acl    = "private"

  tags = {
    Name = "opsschool-nginx-access-log"
  }
}