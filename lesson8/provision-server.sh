#!/usr/bin/env bash
set -euo pipefail

echo "Installing Apache and required tools"

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 openssl curl

echo "Configuring Apache server name"

printf 'ServerName devops.local\n' \
  > /etc/apache2/conf-available/servername.conf

a2enconf servername

echo "Creating the website page"

cat > /var/www/html/index.html <<'HTML'
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title>Lesson 8</title>
</head>
<body>
    <h1>Lesson 8 — Apache</h1>
    <p>Сайт devops.local работает через HTTPS.</p>
</body>
</html>
HTML

echo "Preparing the HTTPS certificate"

if [[ ! -s /etc/ssl/private/devops.local.key || ! -s /etc/ssl/certs/devops.local.crt ]]; then
    openssl req -x509 \
      -newkey rsa:2048 \
      -noenc \
      -sha256 \
      -days 365 \
      -keyout /etc/ssl/private/devops.local.key \
      -out /etc/ssl/certs/devops.local.crt \
      -subj "/CN=devops.local" \
      -addext "subjectAltName=DNS:devops.local,DNS:www.devops.local" \
      -addext "basicConstraints=critical,CA:FALSE" \
      -addext "keyUsage=critical,digitalSignature,keyEncipherment" \
      -addext "extendedKeyUsage=serverAuth"
else
    echo "Existing certificate and key found"
fi

chmod 600 /etc/ssl/private/devops.local.key
chmod 644 /etc/ssl/certs/devops.local.crt

echo "Configuring HTTPS and redirects"

a2enmod ssl alias

cat > /etc/apache2/sites-available/devops-http.conf <<'APACHE'
<VirtualHost *:80>
    ServerName devops.local
    ServerAlias www.devops.local

    Redirect permanent / https://devops.local/
</VirtualHost>
APACHE

cat > /etc/apache2/sites-available/devops-ssl.conf <<'APACHE'
<VirtualHost *:443>
    ServerName devops.local
    DocumentRoot /var/www/html

    SSLEngine on
    SSLProtocol -all +TLSv1.2 +TLSv1.3

    SSLCertificateFile /etc/ssl/certs/devops.local.crt
    SSLCertificateKeyFile /etc/ssl/private/devops.local.key
</VirtualHost>

<VirtualHost *:443>
    ServerName www.devops.local

    SSLEngine on
    SSLProtocol -all +TLSv1.2 +TLSv1.3

    SSLCertificateFile /etc/ssl/certs/devops.local.crt
    SSLCertificateKeyFile /etc/ssl/private/devops.local.key

    Redirect permanent / https://devops.local/
</VirtualHost>
APACHE

a2ensite devops-http.conf devops-ssl.conf
a2dissite 000-default.conf

echo "Sharing the public certificate"

if [[ ! -f /vagrant/Vagrantfile ]]; then
    echo "Shared /vagrant folder is unavailable" >&2
    exit 1
fi

mkdir -p /vagrant/shared
cp /etc/ssl/certs/devops.local.crt /vagrant/shared/devops.local.crt

echo "Checking and starting Apache"

apache2ctl configtest
systemctl enable apache2
systemctl restart apache2

echo "Apache provisioning completed"