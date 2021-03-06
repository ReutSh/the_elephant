# INSTANCES #

resource "aws_instance" "kubernetes_master" {
  ami           = var.ubuntu_18-04
  instance_type = "t2.medium"
  key_name = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_describe_profile.name
  subnet_id = "module.module_vpc_reut.private_subnets_id"
  vpc_security_group_ids = [aws_security_group.master-kubernetes.id, module.module_vpc_reut.default_security_group, aws_security_group.consul-cluster-vpc.id]
  associate_public_ip_address = false
  tags = {
    Name = "project_kubernetes_master_server"
  }

//      connection {
//    user        = "ubuntu"
//    host        = aws_instance.kubernetes_master.private_ip
//    private_key = tls_private_key.tls-key.private_key_pem
//  }
//  provisioner "remote-exec" {
//  }
}

resource "aws_instance" "kubernetes_minions" {
  count = 2
  ami           = var.ubuntu_18-04
  instance_type = "t2.medium"
  key_name = var.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_describe_profile.name
  subnet_id = module.module_vpc_reut.private_subnets_id[count.index]
  vpc_security_group_ids = [aws_security_group.minions-kubernetes.id, module.module_vpc_reut.default_security_group, aws_security_group.consul-cluster-vpc.id]
  associate_public_ip_address = false
  tags = {
    Name = "project_kubernetes_node_server_${count.index+1}"
  }
//      connection {
//    user        = "ubuntu"
//    host = aws_instance.kubernetes_minions[count.index].private_ip
//    private_key = tls_private_key.tls-key.private_key_pem
//  }
//  provisioner "remote-exec" {
//  }
}





# SECURITY GROUPS #

# master #
resource "aws_security_group" "master-kubernetes" {
  vpc_id = module.module_vpc_reut.vpc_id
  name        = "master_kubernetes"
  

  # *** access inbound
    ingress {
    from_port   = 0
    to_port     = 0
    protocol    = 94
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 0
    to_port     = 0
    protocol    = 4
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 10250
    to_port     = 10252
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 179
    to_port     = 179
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8500
    to_port     = 8500
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
    Name = "project-master-kubernetes-sg"
  }
}



# minions #

resource "aws_security_group" "minions-kubernetes" {
  vpc_id = module.module_vpc_reut.vpc_id
  name        = "minions_kubernetes"
  

  # *** access inbound
    ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 0
    to_port     = 0
    protocol    = 4
    cidr_blocks = ["0.0.0.0/0"]
  }


    ingress {
    from_port   = 0
    to_port     = 0
    protocol    = 94
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 30000
    to_port     = 30000
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 30001
    to_port     = 30001
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8500
    to_port     = 8500
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

  
    ingress {
    from_port   = 179
    to_port     = 179
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "project-minions-kubernetes-sg"
  }
}


resource "aws_security_group" "elb-kubernetes" {
  vpc_id = module.module_vpc_reut.vpc_id
  name        = "elb_kubernetes"
  

  # *** access inbound
    ingress {
    from_port   = 30000
    to_port     = 30000
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    from_port   = 30001
    to_port     = 30001
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
    Name = "project-elb-kubernetes-sg"
  }
}






# LOAD-BALANCERS #

# APP-LOAD-BALANCER #
resource "aws_elb" "k8s-lb" {
  name = "project-app-lb"

  security_groups = [
    aws_security_group.elb-kubernetes.id,
    module.module_vpc_reut.default_security_group
  ]

  subnets = [module.module_vpc_reut.public_subnets_id]
  
  listener {
    instance_port     = 30000 
    instance_protocol = "TCP"
    lb_port           = 30000 
    lb_protocol       = "TCP"
  }
  

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:30000"
    interval            = 30
  }

  instances = [aws_instance.kubernetes_minions.*.id]
  tags = {
    Name = "project_application_load_balancer"
  }
}



# OUTPUT #

output "Application_URL" {
  value = "http://${aws_elb.k8s-lb.dns_name}:30000"
}






