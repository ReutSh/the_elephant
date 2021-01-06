# DATA #

data "aws_ami" "ubuntu-18" {
  most_recent = true
  owners      = [var.ubuntu_account_number]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}


# Key Pair #

resource "tls_private_key" "tls-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "project_key" {
  key_name   = var.key_name
  public_key = tls_private_key.tls-key.public_key_openssh

}
  resource  "local_file" "private_key" {
    content      = tls_private_key.tls-key.private_key_pem
    filename = "/home/ubuntu/.ssh/id_rsa"

        provisioner "local-exec" {
    command = "chmod 400 /home/ubuntu/.ssh/id_rsa"
  }

 }



# INSTANCE ROLE & POLICY #

resource "aws_iam_role" "describe-role" {
  name = "describe-role"
  assume_role_policy = file("assume-role-policy.json")
}

resource "aws_iam_policy" "policy-describe-role" {
  name   = "policy-describe-role"
  description = "policy for the role"
  policy = file("ec2_describe_policy.json")
}

resource "aws_iam_policy_attachment" "attachment-policy-describe-role" {
  name = "describe-attachment-policy"
  roles = [aws_iam_role.describe-role.name, ""]
  policy_arn = aws_iam_policy.policy-describe-role.arn
}

resource "aws_iam_instance_profile" "ec2_describe_profile" {
  name  = "ec2_describe_profile"
  role = aws_iam_role.describe-role.name
}
