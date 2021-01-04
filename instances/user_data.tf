locals {
  nginx = <<USERDATA
#!/bin/bash

apt update
apt install nginx awscli -y

# Welcome page changes-
sed -i 's/nginx/OpsSchool Rules/g' /var/www/html/index.nginx-debian.html
sed -i '15,23d' /var/www/html/index.nginx-debian.html
echo "hostname: $HOSTNAME"  >> /var/www/html/index.nginx-debian.html

# Change Nginx configuration to get real user’s IP address in Nginx log files-
echo "set_real_ip_from  ${module.module_vpc_reut.vpc_cidr};" >> /etc/nginx/conf.d/default.conf; echo "real_ip_header    X-Forwarded-For;" >> /etc/nginx/conf.d/default.conf

service nginx restart

# Upload web server access logs to S3 every hour-
echo "0 * * * * aws s3 cp /var/log/nginx/access.log s3://opsschool-nginx-access-log" > /var/spool/cron/crontabs/root

USERDATA
}