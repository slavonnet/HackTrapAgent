#!/usr/bin/env bash
set -euo pipefail

user_name="${HACKTRAP_USER:-trap}"
users_file="/opt/hacktrap/etc/ipsec/users.conf"
enable_l2tp="${IPSEC_ENABLE_L2TP:-true}"
enable_ikev2="${IPSEC_ENABLE_IKEV2:-true}"

to_bool() {
  local value="${1,,}"
  [[ "$value" == "1" || "$value" == "true" || "$value" == "yes" || "$value" == "on" ]]
}

if [[ -f "$users_file" ]]; then
  while IFS=: read -r cfg_user _; do
    [[ -z "${cfg_user// }" ]] && continue
    [[ "${cfg_user:0:1}" == "#" ]] && continue
    user_name="$cfg_user"
    break
  done < "$users_file"
fi

if ! id "$user_name" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$user_name"
fi

enable_l2tp_mode=false
enable_ikev2_mode=false
if to_bool "$enable_l2tp"; then
  enable_l2tp_mode=true
fi
if to_bool "$enable_ikev2"; then
  enable_ikev2_mode=true
fi

if [[ "$enable_l2tp_mode" == "false" && "$enable_ikev2_mode" == "false" ]]; then
  echo "ERROR: both IPsec modes are disabled. Enable IPSEC_ENABLE_L2TP and/or IPSEC_ENABLE_IKEV2."
  exit 1
fi

mkdir -p /run/hacktrap /var/log/ipsec /etc/ipsec.d/private /etc/ipsec.d/certs /etc/ipsec.d/cacerts /etc/xl2tpd /etc/ppp /var/run/xl2tpd
credentials_file="/run/hacktrap/ipsec_credentials.env"
ca_key="/run/hacktrap/ipsec-ca-key.pem"
ca_cert="/etc/ipsec.d/cacerts/ipsec-ca-cert.pem"
server_key="/etc/ipsec.d/private/ipsec-server-key.pem"
server_cert="/etc/ipsec.d/certs/ipsec-server-cert.pem"
l2tp_psk=""
l2tp_user_password=""
ikev2_user_password=""

if [[ "$enable_l2tp_mode" == "true" ]]; then
  l2tp_psk="$(openssl rand -hex 24)"
  l2tp_user_password="$(openssl rand -hex 24)"
fi

if [[ "$enable_ikev2_mode" == "true" ]]; then
  ikev2_user_password="$(openssl rand -hex 24)"
  ipsec pki --gen --type rsa --size 3072 --outform pem > "$ca_key"
  ipsec pki --self --ca --lifetime 3650 --in "$ca_key" --type rsa \
    --dn "CN=HackTrap IPsec CA" --outform pem > "$ca_cert"
  ipsec pki --gen --type rsa --size 3072 --outform pem > "$server_key"
  ipsec pki --pub --in "$server_key" --type rsa | ipsec pki --issue \
    --lifetime 1825 \
    --cacert "$ca_cert" \
    --cakey "$ca_key" \
    --dn "CN=ipsec.hacktrap.local" \
    --san "@ipsec.hacktrap.local" \
    --flag serverAuth \
    --flag ikeIntermediate \
    --outform pem > "$server_cert"
  chmod 600 "$ca_key" "$server_key"
fi

cat > /etc/ipsec.conf <<'EOF'
config setup
  uniqueids = no

EOF

if [[ "$enable_l2tp_mode" == "true" ]]; then
  cat >> /etc/ipsec.conf <<'EOF'
conn l2tp-transport
  keyexchange = ikev1
  authby = secret
  type = transport
  left = %any
  leftid = @ipsec.hacktrap.local
  leftprotoport = 17/1701
  right = %any
  rightprotoport = 17/%any
  ike = aes256-sha1-modp2048,aes128-sha1-modp1024!
  esp = aes256-sha1,aes128-sha1!
  dpdaction = clear
  auto = add
  rekey = no

EOF
fi

if [[ "$enable_ikev2_mode" == "true" ]]; then
  cat >> /etc/ipsec.conf <<'EOF'
conn ikev2-eap
  auto = add
  keyexchange = ikev2
  type = tunnel
  fragmentation = yes
  left = %any
  leftid = @ipsec.hacktrap.local
  leftcert = ipsec-server-cert.pem
  leftsendcert = always
  leftsubnet = 0.0.0.0/0
  right = %any
  rightauth = eap-mschapv2
  rightid = %any
  rightsourceip = 10.40.0.0/24
  rightsendcert = never
  eap_identity = %identity
  ike = aes256-sha256-modp2048,aes128-sha256-modp2048!
  esp = aes256-sha256,aes128-sha256!
  rekey = no
  dpdaction = clear

EOF
fi

{
  if [[ "$enable_l2tp_mode" == "true" ]]; then
    printf "@ipsec.hacktrap.local @trusted-l2tp-client.hacktrap.local : PSK \"%s\"\n" "$l2tp_psk"
  fi
  if [[ "$enable_ikev2_mode" == "true" ]]; then
    printf ": RSA ipsec-server-key.pem\n"
    printf "%s : EAP \"%s\"\n" "$user_name" "$ikev2_user_password"
  fi
} > /etc/ipsec.secrets
chmod 600 /etc/ipsec.secrets

cat > /etc/strongswan.d/charon-logging.conf <<'EOF'
charon {
  filelog {
    ipsec_charon {
      path = /var/log/ipsec/charon.log
      time_format = %b %e %T
      append = no
      default = 2
      flush_line = yes
      ike_name = yes
    }
  }
}
EOF

if [[ "$enable_l2tp_mode" == "true" ]]; then
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
fi

touch /var/log/ipsec/charon.log /var/log/ipsec/xl2tpd.log
chmod 0644 /var/log/ipsec/charon.log /var/log/ipsec/xl2tpd.log

{
  printf "IPSEC_ENABLE_L2TP=%s\n" "$enable_l2tp_mode"
  printf "IPSEC_ENABLE_IKEV2=%s\n" "$enable_ikev2_mode"
  if [[ "$enable_l2tp_mode" == "true" ]]; then
    printf "IPSEC_L2TP_USER=%s\nIPSEC_L2TP_PASSWORD=%s\n" "$user_name" "$l2tp_user_password"
    printf "IPSEC_L2TP_PSK=%s\n" "$l2tp_psk"
  fi
  if [[ "$enable_ikev2_mode" == "true" ]]; then
    printf "IPSEC_IKEV2_EAP_USER=%s\n" "$user_name"
    printf "IPSEC_IKEV2_EAP_PASSWORD=%s\n" "$ikev2_user_password"
    printf "IPSEC_SERVER_ID=@ipsec.hacktrap.local\n"
  fi
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random IPsec runtime credentials."

/usr/sbin/ipsec start --nofork &
pid_ipsec="$!"

pid_xl2tpd=""
if [[ "$enable_l2tp_mode" == "true" ]]; then
  sleep 2
  /usr/sbin/xl2tpd -D &
  pid_xl2tpd="$!"
  sleep 1
  if ! kill -0 "$pid_xl2tpd" >/dev/null 2>&1; then
    echo "WARN: xl2tpd exited, continuing with strongSwan only."
    pid_xl2tpd=""
  fi
fi

cleanup() {
  if [[ -n "${pid_xl2tpd:-}" ]]; then
    kill "$pid_xl2tpd" >/dev/null 2>&1 || true
  fi
  kill "$pid_ipsec" >/dev/null 2>&1 || true
}

trap cleanup TERM INT

set +e
wait "$pid_ipsec"
exit_code="$?"
set -e

cleanup
if [[ -n "${pid_xl2tpd:-}" ]]; then
  wait "$pid_xl2tpd" >/dev/null 2>&1 || true
fi
wait "$pid_ipsec" >/dev/null 2>&1 || true
exit "$exit_code"
