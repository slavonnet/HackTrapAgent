#!/usr/bin/env bash
set -euo pipefail

user_name="${HACKTRAP_USER:-trap}"
users_file="/opt/hacktrap/etc/l2tp/users.conf"

if [[ -f "$users_file" ]]; then
  while IFS=: read -r cfg_user _; do
    [[ -z "${cfg_user// }" ]] && continue
    [[ "${cfg_user:0:1}" == "#" ]] && continue
    user_name="$cfg_user"
    break
  done < "$users_file"
fi

l2tp_psk="$(openssl rand -hex 24)"
l2tp_user_password="$(openssl rand -hex 24)"

if ! id "$user_name" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$user_name"
fi

mkdir -p /run/hacktrap /var/log/l2tp /etc/xl2tpd /etc/ppp
credentials_file="/run/hacktrap/l2tp_credentials.env"
{
  printf "L2TP_SERVICE_USER=%s\nL2TP_SERVICE_PASSWORD=%s\n" "$user_name" "$l2tp_user_password"
  printf "L2TP_PSK=%s\n" "$l2tp_psk"
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random L2TP/IPsec runtime credentials."

cat > /etc/ipsec.conf <<'EOF'
config setup
  uniqueids = no

conn l2tp-transport
  keyexchange = ikev1
  authby = secret
  type = transport
  left = %any
  leftid = @l2tp.hacktrap.local
  leftprotoport = 17/1701
  right = %any
  rightprotoport = 17/%any
  ike = aes256-sha1-modp2048,aes128-sha1-modp1024!
  esp = aes256-sha1,aes128-sha1!
  dpdaction = clear
  auto = add
  rekey = no
EOF

cat > /etc/ipsec.secrets <<EOF
: PSK "${l2tp_psk}"
EOF
chmod 600 /etc/ipsec.secrets

cat > /etc/strongswan.d/charon-logging.conf <<'EOF'
charon {
  filelog {
    /var/log/l2tp/charon.log {
      time_format = %b %e %T
      append = no
      default = 2
      flush_line = yes
      ike_name = yes
    }
  }
}
EOF

cat > /etc/xl2tpd/xl2tpd.conf <<'EOF'
[global]
port = 1701
access control = yes

[lns default]
ip range = 10.30.0.10-10.30.0.100
local ip = 10.30.0.1
refuse chap = no
refuse pap = no
require authentication = yes
name = l2tpd
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
EOF

cat > /etc/ppp/options.xl2tpd <<'EOF'
require-mschap-v2
ms-dns 8.8.8.8
auth
mtu 1280
mru 1280
lock
proxyarp
connect-delay 5000
EOF

cat > /etc/ppp/chap-secrets <<EOF
"${user_name}" l2tpd "${l2tp_user_password}" *
EOF
chmod 600 /etc/ppp/chap-secrets

touch /var/log/l2tp/charon.log /var/log/l2tp/xl2tpd.log
chmod 0644 /var/log/l2tp/charon.log /var/log/l2tp/xl2tpd.log

/usr/sbin/ipsec start --nofork &
pid_ipsec="$!"

sleep 2
/usr/sbin/xl2tpd -D &
pid_xl2tpd="$!"

cleanup() {
  kill "$pid_xl2tpd" "$pid_ipsec" >/dev/null 2>&1 || true
}

trap cleanup TERM INT

set +e
wait -n "$pid_xl2tpd" "$pid_ipsec"
exit_code="$?"
set -e

cleanup
wait "$pid_xl2tpd" "$pid_ipsec" >/dev/null 2>&1 || true
exit "$exit_code"
