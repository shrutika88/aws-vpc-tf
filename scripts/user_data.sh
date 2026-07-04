#!/bin/bash

dnf install -y httpd
systemctl enable httpd
systemctl start httpd

cat <<EOF > /var/www/html/index.html
<h1>Hello from Auto Scaling Group</h1>
EOF
