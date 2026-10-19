#!/usr/bin/env bash
set -euo pipefail

ssh_dir="/home/vagrant/.ssh"
key_file="$ssh_dir/lesson6_server"

install -d -m 700 -o vagrant -g vagrant "$ssh_dir"

if [ ! -f "$key_file" ]; then
    sudo -u vagrant ssh-keygen -t ed25519 -f "$key_file" -N "" -C "lesson6-client"
fi

mkdir -p /vagrant/ssh-keys
cp "$key_file.pub" /vagrant/ssh-keys/client.pub

if ! grep -qFx "192.168.56.11 server" /etc/hosts; then
    printf '%s\n' "192.168.56.11 server" >> /etc/hosts
fi