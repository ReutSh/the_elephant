# INSTANCES
resource "aws_instance" "DB_instances" {
  count                       = var.DB_instances_count
  ami                         = data.aws_ami.ubuntu-18.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = module.vpc_module.private_subnets_id[count.index]
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.DB_instnaces_access.id]

  tags = merge(
    local.common_tags,
  map("Name", "DB-${regex(".$", data.aws_availability_zones.available.names[count.index])}"))
}

resource "aws_security_group" "DB_instnaces_access" {
  vpc_id = module.vpc_module.vpc_id
  name   = "DB-access"

  tags = merge(local.common_tags, map("Name", "DB-access-${module.vpc_module.vpc_id}"))
}

resource "aws_security_group_rule" "DB_ssh_acess" {
  description       = "allow ssh access from anywhere"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.DB_instnaces_access.id
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "DB_outbound_anywhere" {
  description       = "allow outbound traffic to anywhere"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.DB_instnaces_access.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}