#!/bin/bash


#install ansible:
sudo -s <<EOF
echo libc6 libraries/restart-without-asking boolean true | debconf-set-selections
echo libc6:amd64 libraries/restart-without-asking boolean true | debconf-set-selections
echo libpam0g libraries/restart-without-asking boolean true | debconf-set-selections
echo libpam0g:amd64 libraries/restart-without-asking boolean true | debconf-set-selections
EOF
sudo apt update
sudo apt install -y -qq software-properties-common
sudo apt-add-repository -y ppa:ansible/ansible
sudo apt update
sudo apt-get install -y ansible

#install terraform:
sudo apt-get install -y unzip
wget https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_linux_amd64.zip
unzip terraform_0.11.13_linux_amd64.zip
sudo mv terraform /usr/local/bin/

#run terraform by ansible playbook:
ansible-playbook /home/ubuntu/project-configuration/ansible/playbooks/environment_configuration.yaml