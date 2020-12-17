variable "route_tables_names" {
  type    = list(string)
  default = ["public", "private-a", "private-b"]
}

variable "vpc_cidr_block" {
  description = "the cidr block of the vpc, for ex- '10.0.0.0/16'"
}

variable "private_subnets_cidr_list" {
  type    = list(string)
  description = "list of private subnets for ex-['10.0.2.0/24', '10.0.3.0/24']"
}

variable "public_subnets_cidr_list" {
  type    = list(string)
  description = "list of purblic subnets for ex-['10.0.5.0/24', '10.0.6.0/24']"
}

variable region {
  description = "the aws region"
}

variable "external_tags" {
  type = map(string)
  description = "optional - map of external tags which added to vpc module resources"
}

