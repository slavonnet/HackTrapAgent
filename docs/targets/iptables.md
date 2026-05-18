# `iptables` target

## Purpose

The `iptables` target applies temporary bans detected by `fail2ban` inside the project environment.

## Scope

- Ban actions are executed in the `fail2ban` container context.
- Host firewall rules are not directly modified by this project setup.
- Current behavior is intended for local/lab containment and telemetry workflows.

## Operational notes

- Check active jails and ban state:

  ```bash
  sudo docker compose -f docker-compose.yml exec fail2ban fail2ban-client status
  sudo docker compose -f docker-compose.yml exec fail2ban fail2ban-client status <jail-name>
  ```

- Inspect container firewall rules:

  ```bash
  sudo docker compose -f docker-compose.yml exec fail2ban iptables -S
  ```

## Related roadmap items

- Planned additional targets include AbuseIPDB and Webhook forwarding.
- See `docs/ROADMAP.md` for upcoming target integrations.
