#!/usr/bin/env bash
set -euo pipefail
umask 077
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

source /etc/mysql-backup.conf

exec 9>/run/lock/mysql-backup.lock
flock -n 9 || {
    echo "Another backup is already running." >&2
    exit 1
}

mkdir -p "$BACKUP_DIR"

timestamp=$(date +%Y%m%d_%H%M%S)
backup_file="$BACKUP_DIR/${DB_NAME}_${timestamp}.sql"
tmp_file="${backup_file}.tmp"

trap 'rm -f -- "$tmp_file"' EXIT

echo "[$(date -Is)] START database=$DB_NAME"

mysqldump -u root \
    --single-transaction \
    --result-file="$tmp_file" \
    --databases "$DB_NAME"

test -s "$tmp_file"
mv -- "$tmp_file" "$backup_file"

echo "[$(date -Is)] CREATED $backup_file"

rsync -av --timeout=60 --exclude='*.tmp' \
    -e "ssh -i $SSH_KEY -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=10" \
    "$BACKUP_DIR/" \
    "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"

echo "[$(date -Is)] OK copied to $REMOTE_HOST:$REMOTE_DIR"