#!/usr/bin/env bash
set -euo pipefail

user_name="${HACKTRAP_USER:-trap}"
users_file="/opt/hacktrap/etc/ike2/users.conf"

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

ike2_user_password="$(openssl rand -hex 24)"

mkdir -p /run/hacktrap /var/log/ike2 /etc/ipsec.d/private /etc/ipsec.d/certs /etc/ipsec.d/cacerts
credentials_file="/run/hacktrap/ike2_credentials.env"
ca_key="/run/hacktrap/ca-key.pem"
ca_cert="/etc/ipsec.d/cacerts/ike2-ca-cert.pem"
server_key="/etc/ipsec.d/private/ike2-server-key.pem"
server_cert="/etc/ipsec.d/certs/ike2-server-cert.pem"

ipsec pki --gen --type rsa --size 3072 --outform pem > "$ca_key"
ipsec pki --self --ca --lifetime 3650 --in "$ca_key" --type rsa \
  --dn "CN=HackTrap IKEv2 CA" --outform pem > "$ca_cert"
ipsec pki --gen --type rsa --size 3072 --outform pem > "$server_key"
ipsec pki --pub --in "$server_key" --type rsa | ipsec pki --issue \
  --lifetime 1825 \
  --cacert "$ca_cert" \
  --cakey "$ca_key" \
  --dn "CN=ike2.hacktrap.local" \
  --san "@ike2.hacktrap.local" \
  --flag serverAuth \
  --flag ikeIntermediate \
  --outform pem > "$server_cert"
chmod 600 "$ca_key" "$server_key"

cat > /etc/ipsec.conf <<'EOF'
config setup
  uniqueids = no

conn ikev2-eap
  auto = add
  keyexchange = ikev2
  type = tunnel
  fragmentation = yes
  left = %any
  leftid = @ike2.hacktrap.local
  leftcert = ike2-server-cert.pem
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

cat > /etc/ipsec.secrets <<EOF
: RSA ike2-server-key.pem
${user_name} : EAP "${ike2_user_password}"
EOF
chmod 600 /etc/ipsec.secrets

cat > /etc/strongswan.d/charon-logging.conf <<'EOF'
charon {
  filelog {
    ike2_charon {
      path = /var/log/ike2/charon.log
      time_format = %b %e %T
      append = no
      default = 2
      flush_line = yes
      ike_name = yes
    }
  }
}
EOF

touch /var/log/ike2/charon.log
chmod 0644 /var/log/ike2/charon.log

{
  printf "IKE2_EAP_USER=%s\n" "$user_name"
  printf "IKE2_EAP_PASSWORD=%s\n" "$ike2_user_password"
  printf "IKE2_SERVER_ID=@ike2.hacktrap.local\n"
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random IKEv2 runtime credentials and certificates."

exec /usr/sbin/ipsec start --nofork
