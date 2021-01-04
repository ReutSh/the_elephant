##########################################
### INSTANCES ###
##########################################

#MySQL#

resource "aws_instance" "MySQL_master" {
  ami           = "${var.ubuntu_18-04}"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.project_key.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.ec2_describe_profile.name}"
  subnet_id = "${element(data.aws_subnet_ids.private_subnets.ids, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.MySQL.id}" , "${data.aws_security_groups.default_group.ids[0]}" ,"${aws_security_group.consul-cluster-vpc.id}"]
  associate_public_ip_address = false
  tags = {
    Name = "project_MySQL_master_server"
  }

        connection {
    user        = "ubuntu"
    host        = "${aws_instance.MySQL_master.private_ip}"
    private_key = "${tls_private_key.tls-key.private_key_pem}"
  }
  provisioner "remote-exec" {
  }
}


resource "aws_instance" "MySQL_slave" {
  ami           = "${var.ubuntu_18-04}"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.project_key.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.ec2_describe_profile.name}"
  subnet_id = "${element(data.aws_subnet_ids.private_subnets.ids, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.MySQL.id}" , "${data.aws_security_groups.default_group.ids[0]}" ,"${aws_security_group.consul-cluster-vpc.id}"]
  associate_public_ip_address = false
  tags = {
    Name = "project_MySQL_slave_server"
  }

          connection {
    user        = "ubuntu"
    host        = "${aws_instance.MySQL_slave.private_ip}"
    private_key = "${tls_private_key.tls-key.private_key_pem}"
  }
  provisioner "remote-exec" {
  }
}


##########################################
### SECURITY GROUPS ###
##########################################
resource "aws_security_group" "MySQL" {
  vpc_id = "${data.aws_vpcs.myvpc.ids[0]}"
  name        = "MySQL"
  

  # 8080 access inbound
    ingress {
    from_port   = 1186
    to_port     = 1186
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }


  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project-MySQL"
  }
}