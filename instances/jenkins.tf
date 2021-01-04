# INSTANCES #


# JENKINS #
resource "aws_instance" "jenkins_master" {
  ami           = var.ubuntu_18-04
  instance_type = "t2.micro"
  key_name = aws_key_pair.project_key.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_describe_profile.name
  subnet_id = data.aws_subnet_ids.public_subnets.ids[count.index]
  vpc_security_group_ids = [aws_security_group.master-jenkins.id, data.aws_security_groups.default_group.ids[0]] 
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
  key_name = aws_key_pair.project_key.key_name
  subnet_id = data.aws_subnet_ids.private_subnets.ids[count.index]
  iam_instance_profile = aws_iam_instance_profile.ec2_describe_profile.name
  vpc_security_group_ids = [data.aws_security_groups.default_group.ids[0] ,aws_security_group.consul-cluster-vpc.id] 
  associate_public_ip_address = false
  tags = {
    Name = "project_jenkins_slave_server_${count.index+1}"
  }
    connection {
    user        = "ubuntu"
    private_key = tls_private_key.tls-key.private_key_pem
  }
  provisioner "remote-exec" {
  }
}



# SECURITY GROUPS #

resource "aws_security_group" "master-jenkins" {
  vpc_id = "${data.aws_vpcs.myvpc.ids[0]}"
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