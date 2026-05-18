#!/usr/bin/env bash
set -euo pipefail

export_path="${NFS_EXPORT_PATH:-/srv/nfs/export}"
pseudo_path="${NFS_PSEUDO_PATH:-/export}"
allowed_clients="${NFS_ALLOWED_CLIENTS:-127.0.0.1/32}"
log_level="${NFS_LOG_LEVEL:-DEBUG}"
template_path="/opt/hacktrap/etc/nfs/ganesha.conf.tpl"
target_conf="/etc/ganesha/ganesha.conf"

mkdir -p /var/log/nfs /var/run/ganesha "$export_path"
touch /var/log/nfs/ganesha.log
chmod 0644 /var/log/nfs/ganesha.log
chmod 0755 "$export_path"

export NFS_EXPORT_PATH="$export_path"
export NFS_PSEUDO_PATH="$pseudo_path"
export NFS_ALLOWED_CLIENTS="$allowed_clients"
export NFS_LOG_LEVEL="$log_level"

envsubst '${NFS_EXPORT_PATH} ${NFS_PSEUDO_PATH} ${NFS_ALLOWED_CLIENTS} ${NFS_LOG_LEVEL}' \
  < "$template_path" > "$target_conf"

rpcbind -w

exec ganesha.nfsd -F -f "$target_conf" -L /var/log/nfs/ganesha.log
