# INSTANCES #


# JENKINS #
resource "aws_instance" "jenkins_master" {
  ami           = var.ubuntu_18-04
  instance_type = "t2.micro"
  key_name = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_describe_profile.name
  subnet_id = "module.module_vpc_reut.public_subnets_id"
  vpc_security_group_ids = [aws_security_group.master-jenkins.id, module.module_vpc_reut.default_security_group]
  associate_public_ip_address = true
  tags = {
    Name = "project_jenkins_master_server"
  }
    connection {
    user        = "ubuntu"
    host        = aws_instance.jenkins_master.private_ip
    private_key = tls_private_key.tls-key.private_key_pem
  }
  provisioner "remote-exec" {
  }

}

resource "aws_instance" "jenkins_slaves" {
  count = 2
  ami           = var.ubuntu_18-04
  instance_type = "t2.micro"
  key_name = var.key_name
  subnet_id = module.module_vpc_reut.private_subnets_id[count.index]
  iam_instance_profile = aws_iam_instance_profile.ec2_describe_profile.name
  vpc_security_group_ids = [module.module_vpc_reut.default_security_group, aws_security_group.consul-cluster-vpc.id]
  associate_public_ip_address = false
  tags = {
    Name = "project_jenkins_slave_server_${count.index+1}"
  }
    connection {
    user = "ubuntu"
    host = aws_instance.jenkins_slaves[count.index].private_ip
    private_key = tls_private_key.tls-key.private_key_pem
  }
  provisioner "remote-exec" {
  }
}



# SECURITY GROUPS #

resource "aws_security_group" "master-jenkins" {
  vpc_id = module.module_vpc_reut.vpc_id
  name        = "jenkins8080"
  

  # 8080 access inbound #
    ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access #
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project-jenkins-8080"
  }
}


# OUTPUT #

output "Jenkins_URL" {
  value = "http://${aws_instance.jenkins_master.public_ip}:8080"
} 