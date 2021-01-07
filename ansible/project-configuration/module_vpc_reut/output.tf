# OUTPUT #

 output "public_subnets_id" {
  value = aws_subnet.public_subnet.*.id
}

output "private_subnets_id" {
  value = aws_subnet.private_subnet.*.id
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.vpc.cidr_block
}

output "ansible_public_ip" {
  value = aws_instance.ansible_server.public_ip
}

output "default_security_group" {
  value = aws_default_security_group.default.id
}