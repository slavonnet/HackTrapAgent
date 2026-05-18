# Testing

Tests are split by service.

## Shared test helpers

- `tests/common/compose_test_lib.sh` contains shared setup and validation helpers.
- `config/services.env` is the single source of truth for enabled services and test defaults.

## Service tests

- `tests/ssh/test_fail2ban_scope.sh` — validates SSH + fail2ban:
  - IP ban after repeated failed logins
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host
- `tests/ftp/test_fail2ban_scope.sh` — validates FTP + fail2ban:
  - IP ban after repeated failed logins
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host
- `tests/l2tp/test_fail2ban_scope.sh` — validates L2TP + fail2ban:
  - IP ban after repeated failed real IKEv1/IPsec authentication attempts
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host
- `tests/ike2/test_fail2ban_scope.sh` — validates IKEv2 + fail2ban:
  - IP ban after repeated failed real IKEv2 certificate/EAP authentication attempts
- `tests/bgp/test_fail2ban_scope.sh` — validates BGP + fail2ban:
  - IP ban after repeated unconfigured peer connection attempts
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host
- `tests/openvpn/test_fail2ban_scope.sh` — validates OpenVPN + fail2ban:
  - IP ban after repeated failed UDP probes
  - firewall rule exists inside the fail2ban container scope
  - matching rule is absent on the host

## Run one service

```bash
./tests/ssh/test_fail2ban_scope.sh
./tests/ftp/test_fail2ban_scope.sh
./tests/l2tp/test_fail2ban_scope.sh
./tests/ike2/test_fail2ban_scope.sh
./tests/bgp/test_fail2ban_scope.sh
./tests/openvpn/test_fail2ban_scope.sh
```

## Run selected services

```bash
./tests/run_service_tests.sh ssh ftp bgp l2tp ike2 openvpn
```

`run_service_tests.sh` runs service tests in parallel.

When no service arguments are passed, it runs tests for `ENABLED_SERVICES` from `config/services.env`.
