#!/bin/bash
set -eux

# Update packages
dnf update -y

# Install Apache + PHP + MySQL driver
dnf install -y \
    httpd \
    php \
    php-mysqlnd

# Enable and start Apache
systemctl enable httpd
systemctl start httpd

# Create the PHP application
cat >/var/www/html/index.php <<EOF
<?php

\$host = "${db_endpoint}";
\$db   = "${db_name}";
\$user = "${db_user}";
\$pass = "${db_password}";

\$conn = new mysqli(\$host, \$user, \$pass, \$db);

if (\$conn->connect_error) {
    die("Connection failed: " . \$conn->connect_error);
}

\$result = \$conn->query("SELECT * FROM users");

echo "<h1>Users</h1>";
echo "<table border='1'>";
echo "<tr><th>ID</th><th>Name</th><th>Created</th></tr>";

while (\$row = \$result->fetch_assoc()) {
    echo "<tr>";
    echo "<td>{\$row['id']}</td>";
    echo "<td>{\$row['name']}</td>";
    echo "<td>{\$row['created_at']}</td>";
    echo "</tr>";
}

echo "</table>";

?>
EOF

# Restart Apache so it serves the new file
systemctl restart httpd