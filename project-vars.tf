variable aws_region {
description = "the aws region"
default = "us-east-1"
}

variable "vpc_cidr" {
default = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  type        = list(string)
  default = ["10.0.40.0/24", "10.0.50.0/24"]
}

variable "private_subnets_cidr" {
  type        = list(string)
  default = ["10.0.2.0/24", "10.0.3.0/24"]
}

variable "route_tables_names" {
  type    = list(string)
  default = ["public", "private_rt_1","private_rt_2"]  
}

variable "ubuntu_18-04" {
default = "ami-0a313d6098716f372"
}

variable "key_name" {
  default = "ansible_key"
}
