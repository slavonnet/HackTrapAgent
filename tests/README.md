# Testing

Tests are split by service.

## Shared test helpers

- `tests/common/compose_test_lib.sh` contains shared setup and validation helpers.
- `config/services.env` is the single source of truth for enabled services and test defaults.

## Service tests

- `tests/asterisk/test_fail2ban_scope.sh` — validates Asterisk (IAX/PJSIP/AMI/ARI) + fail2ban:
  - service listeners are up on IAX, PJSIP, AMI, and ARI ports
  - IP ban after repeated failed AMI/ARI/PJSIP authentication probes
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host
- `tests/ssh/test_fail2ban_scope.sh` — validates SSH + fail2ban:
  - IP ban after repeated failed logins
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host
- `tests/telnetd/test_fail2ban_scope.sh` — validates Telnet + fail2ban:
  - IP ban after repeated failed logins
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host
- `tests/ftp/test_fail2ban_scope.sh` — validates FTP + fail2ban:
  - IP ban after repeated failed logins
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host
- `tests/ntp/test_fail2ban_scope.sh` — validates NTP + fail2ban:
  - IP ban after repeated suspicious NTP mode 6/7 request probes
- `tests/nfs/test_fail2ban_scope.sh` — validates NFS + fail2ban:
  - IP ban after repeated valid NFSv4 RPC probe requests (`Program 100003`, function `0`/`1`)
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host
- `tests/imap/test_fail2ban_scope.sh` — validates IMAP + fail2ban:
  - IP ban after repeated failed logins
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host
- `tests/pop3/test_fail2ban_scope.sh` — validates POP3 + fail2ban:
  - IP ban after repeated failed logins
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host
- `tests/smtp/test_fail2ban_scope.sh` — validates SMTP + fail2ban:
  - IP ban after repeated failed logins
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host
- `tests/l2tp/test_fail2ban_scope.sh` — validates L2TP + fail2ban:
  - IP ban after repeated failed real IKEv1/IPsec authentication attempts
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host
- `tests/ike2/test_fail2ban_scope.sh` — validates IKEv2 + fail2ban:
  - IP ban after repeated failed real IKEv2 certificate/EAP authentication attempts
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host
- `tests/postgresql/test_fail2ban_scope.sh` — validates PostgreSQL + fail2ban:
  - IP ban after repeated failed logins
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host
- `tests/mysql/test_fail2ban_scope.sh` — validates MySQL + fail2ban:
  - IP ban after repeated failed logins
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host
- `tests/memcached/test_fail2ban_scope.sh` — validates Memcached + fail2ban:
  - IP ban after repeated failed `auth` attempts
- `tests/mongodb/test_fail2ban_scope.sh` — validates MongoDB + fail2ban:
  - IP ban after repeated failed logins
- `tests/redis/test_fail2ban_scope.sh` — validates Redis + fail2ban:
  - IP ban after repeated failed ACL/password authentication attempts
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host
- `tests/elasticsearch/test_fail2ban_scope.sh` — validates Elasticsearch + fail2ban:
  - IP ban after repeated failed HTTP Basic authentication attempts
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host
- `tests/clickhouse/test_fail2ban_scope.sh` — validates ClickHouse + fail2ban:
  - IP ban after repeated failed HTTP authentication attempts
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host
- `tests/bgp/test_fail2ban_scope.sh` — validates BGP + fail2ban:
  - IP ban after repeated unconfigured peer connection attempts
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host
- `tests/openvpn/test_fail2ban_scope.sh` — validates OpenVPN + fail2ban:
  - IP ban after repeated failed UDP probes
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host
- `tests/snmp/test_fail2ban_scope.sh` — validates SNMP + fail2ban:
  - random SNMP community is required (common guesses like `public`/`private` do not work)
  - SNMPv3 authentication is enforced
  - IP ban after repeated failed SNMP authentication attempts
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host
- `tests/snmptrap/test_fail2ban_scope.sh` — validates SNMP trap + fail2ban:
  - random trap community is required
  - SNMPv3 trap authentication is enforced
  - IP ban after repeated unauthorized trap attempts
- `tests/radius/test_fail2ban_scope.sh` — validates RADIUS + fail2ban:
  - IP ban after repeated failed real RADIUS PAP authentication attempts
- `tests/ad/test_fail2ban_scope.sh` — validates AD (LDAP) + fail2ban:
  - IP ban after repeated failed LDAP bind attempts
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host
- `tests/rabbitmq/test_fail2ban_scope.sh` — validates RabbitMQ + fail2ban:
  - IP ban after repeated failed AMQP authentication attempts
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host

## Run one service

```bash
./tests/asterisk/test_fail2ban_scope.sh
./tests/ssh/test_fail2ban_scope.sh
./tests/telnetd/test_fail2ban_scope.sh
./tests/ftp/test_fail2ban_scope.sh
./tests/ntp/test_fail2ban_scope.sh
./tests/nfs/test_fail2ban_scope.sh
./tests/imap/test_fail2ban_scope.sh
./tests/pop3/test_fail2ban_scope.sh
./tests/smtp/test_fail2ban_scope.sh
./tests/l2tp/test_fail2ban_scope.sh
./tests/ike2/test_fail2ban_scope.sh
./tests/postgresql/test_fail2ban_scope.sh
./tests/mysql/test_fail2ban_scope.sh
./tests/memcached/test_fail2ban_scope.sh
./tests/mongodb/test_fail2ban_scope.sh
./tests/redis/test_fail2ban_scope.sh
./tests/elasticsearch/test_fail2ban_scope.sh
./tests/clickhouse/test_fail2ban_scope.sh
./tests/bgp/test_fail2ban_scope.sh
./tests/openvpn/test_fail2ban_scope.sh
./tests/snmp/test_fail2ban_scope.sh
./tests/snmptrap/test_fail2ban_scope.sh
./tests/radius/test_fail2ban_scope.sh
./tests/ad/test_fail2ban_scope.sh
./tests/rabbitmq/test_fail2ban_scope.sh
```

## Run selected services

```bash
./tests/run_service_tests.sh asterisk ssh telnetd ftp ntp nfs postgresql mysql memcached mongodb redis elasticsearch clickhouse bgp l2tp ike2 openvpn radius imap pop3 smtp ad rabbitmq rdp snmp snmptrap
```

`run_service_tests.sh` runs service tests in parallel.

When no service arguments are passed, it runs tests for `ENABLED_SERVICES` from `config/services.env`.
