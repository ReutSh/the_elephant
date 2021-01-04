# INSTANCES
resource "aws_instance" "nginx" {
  count                       = var.nginx_instances_count
  iam_instance_profile        = aws_iam_instance_profile.nginx_instance.name
  associate_public_ip_address = true
  ami                         = data.aws_ami.ubuntu-18.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = module.module_vpc_reut.public_subnets_id[count.index]
  vpc_security_group_ids      = [aws_security_group.nginx_instances_access.id]
  user_data                   = local.nginx

  root_block_device {
    encrypted   = false
    volume_type = "gp2"
    volume_size = "10"
  }

  ebs_block_device {
    device_name = "xvdh"
    volume_type = "gp2"
    volume_size = "10"
    encrypted   = true
  }

  tags = merge(
    local.common_tags,
    map(
      "Name", "nginx-web-${regex(".$", data.aws_availability_zones.available.names[count.index])}"
    )
  )
}


resource "aws_security_group" "nginx_instances_access" {
  vpc_id = module.module_vpc_reut.vpc_id
  name   = "nginx-access"

  tags = merge(
    local.common_tags,
    map(
      "Name", "nginx-access-${module.module_vpc_reut.vpc_id}"
    )
  )
}

resource "aws_security_group_rule" "nginx_http_acess" {
  description       = "allow http access from anywhere"
  from_port         = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.nginx_instances_access.id
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "nginx_ssh_acess" {
  description       = "allow ssh access from anywhere"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.nginx_instances_access.id
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "nginx_outbound_anywhere" {
  description       = "allow outbound traffic to anywhere"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.nginx_instances_access.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Instance Profile

resource "aws_iam_role" "nginx_web_role" {
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

data "aws_iam_policy_document" "s3_nginx_logs_put_access_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "s3:Put*",
      "s3:Get*",
      "s3:ListBucket"
    ]
    resources = [
      "${aws_s3_bucket.nginx_access_log.arn}/*",
      aws_s3_bucket.nginx_access_log.arn
    ]
  }
}


resource "aws_iam_policy" "s3_nginx_logs_put_access_policy" {
  name   = "s3_nginx_logs_put_access_policy"
  policy = data.aws_iam_policy_document.s3_nginx_logs_put_access_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "attach_s3_access_to_nginx_role" {
  policy_arn = aws_iam_policy.s3_nginx_logs_put_access_policy.arn
  role       = aws_iam_role.nginx_web_role.name
}

resource "aws_iam_instance_profile" "nginx_instance" {
  name = "nginx_instance_profile"
  role = aws_iam_role.nginx_web_role.name
}

