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
  type = string
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

variable "profile" {
  default = "ops-school"
}

variable "ubuntu_18-04" {
default = "ami-0a313d6098716f372"
}

