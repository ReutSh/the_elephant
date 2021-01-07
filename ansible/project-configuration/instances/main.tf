module "module_vpc_reut" {
  source               = "..\/..\/..\/module_vpc_reut"
  vpc_cidr             = "10.0.0.0/16"
  public_subnets_cidr  = ["10.0.5.0/24", "10.0.6.0/24"] 
  private_subnets_cidr = ["10.0.3.0/24", "10.0.4.0/24"]
  aws_region           = "us-east-1"
}