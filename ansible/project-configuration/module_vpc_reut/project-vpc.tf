#DATA
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "vpc" {
  enable_dns_hostnames = "true" 
  cidr_block           = var.vpc_cidr
tags = {
    Name    = "project_vpc_reut"
  }
}

# Subnets : public
resource aws_subnet "public_subnet" {
  count                   = length(var.public_subnets_cidr)
  map_public_ip_on_launch = "true"
  cidr_block              = var.public_subnets_cidr[count.index]
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "public_subnet_${data.aws_availability_zones.available.names[count.index + 1]}"
  }
}

#Subnets : private
resource aws_subnet "private_subnet" {
  count                   = length(var.private_subnets_cidr)
  map_public_ip_on_launch = "false"
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_subnets_cidr[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "private_subnet_${data.aws_availability_zones.available.names[count.index + 1]}"
  }
}

#Nat gatways for the private subnets
resource "aws_nat_gateway" "nat_project" {
  count         = length(var.public_subnets_cidr)
  allocation_id = aws_eip.nat.*.id[count.index]
  subnet_id     = aws_subnet.public_subnet.*.id[count.index]
  tags = {
    Name = "nat-project-${data.aws_availability_zones.available.names[count.index + 1]}"
  }
}

# Internet Gateway
resource aws_internet_gateway "reut_igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "igw-project"
  }
}


# EIP #
resource "aws_eip" "nat" {
count = length(var.public_subnets_cidr)
tags = {
    Name = "project-elastic-ip-${data.aws_availability_zones.available.names[count.index + 1]}"
  }
}


# SECURITY GROUPS #
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id

# SSH access inbound #
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    Name = "project-default_sg"
  }
}


# INSTANCE ROLE & POLICY #

resource "aws_iam_role" "ansible-role" {
  name = "ansible-role"
  assume_role_policy = file("assume-role-policy.json")
}

resource "aws_iam_policy" "policy-ansible-role" {
  name   = "ansible-policy-role"
  description = "policy for the role"
  policy = file("ansible_policy.json")
}

resource "aws_iam_policy_attachment" "attachment-policy-ansible-role" {
  name       = "ansible-attachment-policy"
  roles      = [aws_iam_role.ansible-role.name, ""]
  policy_arn = aws_iam_policy.policy-ansible-role.arn
}


resource "aws_iam_instance_profile" "ansible_profile" {
  name  = "ansible_profile"
  role = aws_iam_role.ansible-role.name
}


# Ansible Instance #

resource "aws_instance" "ansible_server" {
  ami                         = var.ubuntu_18-04
  instance_type               = "t2.micro"
  subnet_id                   = "aws_subnet.public_subnet.*.id"
  vpc_security_group_ids      = [aws_default_security_group.default.id, ""]
  associate_public_ip_address = true
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.ansible_profile.name

  connection {
    user        = "ubuntu"
    host        = aws_instance.ansible_server.public_ip
  }
  provisioner "file" {
    source      = "../ansible-server-transfer/project-configuration"
    destination = "~/"
  }
  provisioner "remote-exec" {
  script = "./installation.sh"
  }

  tags = {
    Name = "project_ansible_server"
    Monitor = "yes"
  }
}

resource "null_resource" "configure_systems" {
  provisioner "remote-exec" {
    inline = [ "ansible-playbook /home/ubuntu/project-configuration/ansible/playbooks/systems_configuration.yaml" ]
  }

  connection {
    host = aws_instance.ansible_server.*.public_ip
    user        = "ubuntu"
  }

}






