# INSTANCES #
resource "aws_instance" "consul_master" {
  ami           = var.ubuntu_18-04
  instance_type = "t2.micro"
  key_name = var.key_name
  subnet_id = module.module_vpc_reut.private_subnets.*.id[count.index]
  vpc_security_group_ids = [aws_security_group.consul-cluster-vpc.id , module.module_vpc_reut.aws__default_security_group.default.ids[0]]
  associate_public_ip_address = false
  iam_instance_profile = aws_iam_instance_profile.consul-instance-profile.name
  tags = {
    Name = "project_consul_master_server"
    Consul = "yes"
  }
  connection {
    user        = "ubuntu"
    host        = aws_instance.consul_master.private_ip
    private_key = tls_private_key.tls-key.private_key_pem
  } 
  
  provisioner "remote-exec" {
  }

}


resource "aws_instance" "consul_nodes" {
  count = 2
  ami           = var.ubuntu_18-04
  instance_type = "t2.micro"
  key_name = var.key_name
  subnet_id = module.module_vpc_reut.private_subnets.id[count.index]
  vpc_security_group_ids = [aws_security_group.consul-cluster-vpc.id , module.module_vpc_reut.aws__default_security_group.default.ids[0]]
  associate_public_ip_address = false
  iam_instance_profile = aws_iam_instance_profile.consul-instance-profile.name
  tags = {
    Name = "project_consul_node_server_${count.index+1}"
    Consul = "yes"
  }
  connection {
    user        = "ubuntu"
    private_key = tls_private_key.tls-key.private_key_pem
  }
  provisioner "remote-exec" {
  }

}


# LOAD-BALANCER #

resource "aws_elb" "consul-lb" {
  name = "project-consul-lb"

  security_groups = [
    aws_security_group.consul-cluster-vpc.id,
    data.aws_security_groups.default_group.ids[0]
  ]

  subnets = [data.aws_subnet_ids.public_subnets.ids]
  
  listener {
    instance_port     = 8500
    instance_protocol = "http"
    lb_port           = 8500
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8500/ui/"
    interval            = 30
  }

  instances = [aws_instance.consul_master.id , aws_instance.consul_nodes.*.id]
  tags = {
    Name = "project_consul_load_balancer"
  }
}


# SECURITY GROUPS #
// a vpc security group to allow all items in the vpc to communicate between them.

resource "aws_security_group" "consul-cluster-vpc" {
  name        = "consul-cluster-vpc"
  description = "Default security group that allows inbound and outbound traffic from all instances in the VPC"
  vpc_id      = module.module_vpc_reut.vpc_id

  ingress {
    from_port = "8300"
    to_port   = "8300"
    protocol  = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = "8301"
    to_port   = "8301"
    protocol  = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = "8302"
    to_port   = "8302"
    protocol  = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port = "8400"
    to_port   = "8400"
    protocol  = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = "8500"
    to_port   = "8500"
    protocol  = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  
  ingress {
    from_port = "8600"
    to_port   = "8600"
    protocol  = "UDP"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port = "8600"
    to_port   = "8600"
    protocol  = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
  }

  tags = {
    Name    = "Project-Consul Cluster Int-VPC"
  }
}




# POLICY #


// A policy to allow an instance to forward logs to CloudWatch, and
//  create the Log Stream or Log Group if it doesn't exist.
resource "aws_iam_policy" "logs-forward" {
  name        = "consul-node-logs-forward"
  path        = "/"
  description = "Allows an instance to forward logs to CloudWatch"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
    ],
      "Resource": [
        "arn:aws:logs:*:*:*"
    ]
  }
 ]
}
    EOF
}

// policy to allow an instance to discover the consul cluster leader.
resource "aws_iam_policy" "discovery-leader" {
  name        = "consul-node-discovery-leader"
  path        = "/"
  description = "This policy allows a consul server to discover a consul leader by examining the instances in a consul cluster Auto-Scaling group. It needs to describe the instances in the auto scaling group, then check the IPs of the instances."

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1468377974000",
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeAutoScalingGroups",
                "ec2:DescribeInstances"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
    EOF
}

//  Create a role which consul instances will assume.
//  This role has a policy saying it can be assumed by ec2
//  instances.
resource "aws_iam_role" "consul-instance-role" {
  name = "consul-instance-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

//  Attach the policies to the role.
resource "aws_iam_policy_attachment" "consul-instance-forward-logs" {
  name       = "consul-instance-forward-logs"
  roles      = aws_iam_role.consul-instance-role.name
  policy_arn = aws_iam_policy.forward-logs.arn
}

resource "aws_iam_policy_attachment" "consul-instance-leader-discovery" {
  name       = "consul-instance-leader-discovery"
  roles      = aws_iam_role.consul-instance-role.name
  policy_arn = aws_iam_policy.leader-discovery.arn
}

//  Create a instance profile for the role.
resource "aws_iam_instance_profile" "consul-instance-profile" {
  name  = "consul-instance-profile"
  role = aws_iam_role.consul-instance-role.name
}