#!/usr/bin/env bash
set -euo pipefail

ssh_dir="/home/vagrant/.ssh"
public_key="/vagrant/ssh-keys/client.pub"
authorized_keys="$ssh_dir/authorized_keys"

if [ ! -s "$public_key" ]; then
    echo "Публичный ключ отсутствует. Сначала выполни vagrant provision client" >&2
    exit 1
fi

install -d -m 700 -o vagrant -g vagrant "$ssh_dir"
touch "$authorized_keys"

if ! grep -qFx -f "$public_key" "$authorized_keys"; then
    cat "$public_key" >> "$authorized_keys"
fi

chown vagrant:vagrant "$authorized_keys"
chmod 600 "$authorized_keys"