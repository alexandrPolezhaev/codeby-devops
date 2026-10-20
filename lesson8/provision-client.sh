#!/usr/bin/env bash
set -euo pipefail

echo "Installing client tools"

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y curl ca-certificates openssl

echo "Configuring local website names"

sed -i '/# lesson8-web$/d' /etc/hosts

printf '%s\n' \
  '192.168.56.11 devops.local www.devops.local # lesson8-web' \
  >> /etc/hosts

echo "Installing the trusted website certificate"

if [[ ! -s /vagrant/shared/devops.local.crt ]]; then
    echo "Certificate not found. Run server provisioning first." >&2
    exit 1
fi

install -m 0644 \
  /vagrant/shared/devops.local.crt \
  /usr/local/share/ca-certificates/devops.local.crt

update-ca-certificates

echo "Client provisioning completed"
