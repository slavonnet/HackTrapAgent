#!/usr/bin/env bash
set -euo pipefail

user_name="${HACKTRAP_USER:-trap}"
users_file="/opt/hacktrap/etc/ad/users.conf"
base_dn="dc=hacktrap,dc=local"
admin_dn="cn=admin,${base_dn}"

if [[ -f "$users_file" ]]; then
  while IFS=: read -r cfg_user _; do
    [[ -z "${cfg_user// }" ]] && continue
    [[ "${cfg_user:0:1}" == "#" ]] && continue
    user_name="$cfg_user"
    break
  done < "$users_file"
fi

if [[ ! "$user_name" =~ ^[A-Za-z0-9_]+$ ]]; then
  echo "Invalid AD runtime user: '$user_name'"
  exit 1
fi

service_dn="uid=${user_name},ou=people,${base_dn}"

admin_password="$(openssl rand -hex 24)"
service_password="$(openssl rand -hex 24)"
admin_password_hash="$(slappasswd -s "$admin_password")"
service_password_hash="$(slappasswd -s "$service_password")"

mkdir -p /run/hacktrap /var/log/ad /run/slapd /var/lib/ldap
touch /var/log/ad/slapd.log
chmod 0644 /var/log/ad/slapd.log
chown -R openldap:openldap /var/lib/ldap /run/slapd

sed "s|__ROOTPW_HASH__|${admin_password_hash}|g" /opt/hacktrap/etc/ad/slapd.conf.template > /etc/ldap/slapd.conf
cp /opt/hacktrap/etc/ad/rsyslog-slapd.conf /etc/rsyslog.d/10-slapd.conf

rm -rf /var/lib/ldap/*
cat > /tmp/bootstrap.ldif <<EOF
dn: ${base_dn}
objectClass: dcObject
objectClass: organization
o: HackTrap LDAP Directory
dc: hacktrap

dn: ou=people,${base_dn}
objectClass: organizationalUnit
ou: people

dn: ${admin_dn}
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin
description: LDAP administrator
userPassword: ${admin_password_hash}

dn: ${service_dn}
objectClass: inetOrgPerson
uid: ${user_name}
sn: ${user_name}
cn: ${user_name}
userPassword: ${service_password_hash}
EOF

slapadd -f /etc/ldap/slapd.conf -l /tmp/bootstrap.ldif
chown -R openldap:openldap /var/lib/ldap
rm -f /tmp/bootstrap.ldif

rsyslogd

credentials_file="/run/hacktrap/ad_credentials.env"
{
  printf "AD_BASE_DN=%s\nAD_ADMIN_DN=%s\nAD_ADMIN_PASSWORD=%s\n" "$base_dn" "$admin_dn" "$admin_password"
  printf "AD_SERVICE_USER=%s\nAD_SERVICE_DN=%s\nAD_SERVICE_PASSWORD=%s\n" "$user_name" "$service_dn" "$service_password"
} > "$credentials_file"
chmod 600 "$credentials_file"
echo "Generated random LDAP credentials for runtime users."

exec /usr/sbin/slapd -f /etc/ldap/slapd.conf -h "ldap://0.0.0.0:389/" -u openldap -g openldap
