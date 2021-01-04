locals {
  common_tags = {
    Owner   = "Reut"
    Purpose = "Opsschool-Project"
  }
}

variable "instance_type" {
  description = "The type of the ec2, for example - t2.medium"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  default     = "opsschool"
  description = "The key name of the Key Pair to use for the instance"
  type        = string
}

variable "ubuntu_account_number" {
  default = "099720109477"
}

variable "nginx_instances_count" {
  default = 2
}

variable "DB_instances_count" {
  default = 2
}

variable region {
  default = "us-east-1"
}

variable "aws_profile" {
  default = "reut"
}
