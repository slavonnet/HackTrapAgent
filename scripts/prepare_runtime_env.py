#!/usr/bin/env python3
"""Prepare runtime services env with automatic port conflict resolution."""

from __future__ import annotations

import argparse
import socket
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Set, Tuple


@dataclass(frozen=True)
class PortSpec:
    env_var: str
    protocols: Tuple[str, ...]


SERVICE_PORT_SPECS: Dict[str, List[PortSpec]] = {
    "asterisk": [
        PortSpec("ASTERISK_PJSIP_PUBLIC_PORT", ("tcp", "udp")),
        PortSpec("ASTERISK_IAX_PUBLIC_PORT", ("udp",)),
        PortSpec("ASTERISK_MANAGER_PUBLIC_PORT", ("tcp",)),
        PortSpec("ASTERISK_ARI_PUBLIC_PORT", ("tcp",)),
    ],
    "ssh": [PortSpec("SSH_PUBLIC_PORT", ("tcp",))],
    "telnetd": [PortSpec("TELNETD_PUBLIC_PORT", ("tcp",))],
    "ftp": [PortSpec("FTP_PUBLIC_PORT", ("tcp",))],
    "ntp": [PortSpec("NTP_PUBLIC_PORT", ("udp",))],
    "nfs": [PortSpec("NFS_PUBLIC_PORT", ("tcp",))],
    "postgresql": [PortSpec("POSTGRESQL_PUBLIC_PORT", ("tcp",))],
    "mysql": [PortSpec("MYSQL_PUBLIC_PORT", ("tcp",))],
    "memcached": [PortSpec("MEMCACHED_PUBLIC_PORT", ("tcp",))],
    "mongodb": [PortSpec("MONGODB_PUBLIC_PORT", ("tcp",))],
    "redis": [PortSpec("REDIS_PUBLIC_PORT", ("tcp",))],
    "bgp": [PortSpec("BGP_PUBLIC_PORT", ("tcp",))],
    "openvpn": [PortSpec("OPENVPN_PUBLIC_PORT", ("udp",))],
    "smb": [PortSpec("SMB_PUBLIC_PORT", ("tcp",))],
    "kafka": [PortSpec("KAFKA_PUBLIC_PORT", ("tcp",))],
    "l2tp": [
        PortSpec("L2TP_PUBLIC_PORT", ("udp",)),
        PortSpec("L2TP_IKE_PUBLIC_PORT", ("udp",)),
        PortSpec("L2TP_NATT_PUBLIC_PORT", ("udp",)),
    ],
    "ike2": [
        PortSpec("IKE2_PUBLIC_PORT", ("udp",)),
        PortSpec("IKE2_NATT_PUBLIC_PORT", ("udp",)),
    ],
    "imap": [PortSpec("IMAP_PUBLIC_PORT", ("tcp",))],
    "pop3": [PortSpec("POP3_PUBLIC_PORT", ("tcp",))],
    "smtp": [PortSpec("SMTP_PUBLIC_PORT", ("tcp",))],
    "elasticsearch": [PortSpec("ELASTICSEARCH_PUBLIC_PORT", ("tcp",))],
    "clickhouse": [
        PortSpec("CLICKHOUSE_HTTP_PUBLIC_PORT", ("tcp",)),
        PortSpec("CLICKHOUSE_NATIVE_PUBLIC_PORT", ("tcp",)),
    ],
    "ad": [PortSpec("AD_PUBLIC_PORT", ("tcp",))],
    "radius": [PortSpec("RADIUS_PUBLIC_PORT", ("udp",))],
    "rabbitmq": [
        PortSpec("RABBITMQ_PUBLIC_PORT", ("tcp",)),
        PortSpec("RABBITMQ_MANAGEMENT_PUBLIC_PORT", ("tcp",)),
    ],
    "rdp": [PortSpec("RDP_PUBLIC_PORT", ("tcp",))],
    "snmp": [PortSpec("SNMP_PUBLIC_PORT", ("udp",))],
    "snmptrap": [PortSpec("SNMPTRAP_PUBLIC_PORT", ("udp",))],
}


def parse_env_file(config_path: Path) -> Tuple[List[str], Dict[str, str]]:
    order: List[str] = []
    values: Dict[str, str] = {}
    for raw in config_path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        values[key] = value.strip()
        order.append(key)
    return order, values


def split_csv(value: str) -> List[str]:
    return [item.strip() for item in value.split(",") if item.strip()]


def parse_listening_ports(protocol: str) -> Set[int]:
    cmd = ["netstat", "-lnt"] if protocol == "tcp" else ["netstat", "-lnu"]
    try:
        output = subprocess.run(cmd, check=True, capture_output=True, text=True).stdout
    except subprocess.CalledProcessError:
        return set()

    ports: Set[int] = set()
    for line in output.splitlines():
        parts = line.split()
        if len(parts) < 4:
            continue
        local_addr = parts[3]
        # supported formats: 0.0.0.0:22, :::22, *:22
        if ":" not in local_addr:
            continue
        port_text = local_addr.rsplit(":", 1)[1]
        if not port_text.isdigit():
            continue
        ports.add(int(port_text))
    return ports


def find_available_port(
    desired_port: int,
    protocols: Iterable[str],
    reserved: Dict[str, Set[int]],
    host_used: Dict[str, Set[int]],
) -> int | None:
    protocols_tuple = tuple(protocols)

    def is_free(candidate: int) -> bool:
        for proto in protocols_tuple:
            if candidate in reserved[proto]:
                return False
            if candidate in host_used[proto]:
                return False
        return True

    candidate_sequence: List[int] = []
    candidate_sequence.append(desired_port)
    for offset in (10000, 20000, 30000):
        if desired_port + offset <= 65535:
            candidate_sequence.append(desired_port + offset)

    for candidate in candidate_sequence:
        if is_free(candidate):
            return candidate

    search_start = max(10000, desired_port + 1)
    for candidate in range(search_start, 65536):
        if is_free(candidate):
            return candidate
    return None


def write_env_file(output_path: Path, ordered_keys: List[str], values: Dict[str, str]) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    lines = ["# Generated by scripts/prepare_runtime_env.py"]
    for key in ordered_keys:
        lines.append(f"{key}={values.get(key, '')}")
    output_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Prepare runtime services env with resolved ports.")
    parser.add_argument("--config", required=True, help="Path to source services env file.")
    parser.add_argument("--output", required=True, help="Path to generated runtime env file.")
    parser.add_argument("--quiet", action="store_true", help="Suppress resolution summary output.")
    args = parser.parse_args()

    config_path = Path(args.config)
    output_path = Path(args.output)
    order, values = parse_env_file(config_path)

    enabled_services = split_csv(values.get("ENABLED_SERVICES", ""))
    fail2ban_services = split_csv(values.get("FAIL2BAN_SERVICES", ""))

    host_used = {
        "tcp": parse_listening_ports("tcp"),
        "udp": parse_listening_ports("udp"),
    }
    reserved = {"tcp": set(), "udp": set()}

    resolved_services: List[str] = []
    changes: List[str] = []
    disabled: List[str] = []

    for service in enabled_services:
        specs = SERVICE_PORT_SPECS.get(service, [])
        service_reservations: List[Tuple[str, int]] = []
        service_changes: List[str] = []
        service_ok = True

        for spec in specs:
            current_raw = values.get(spec.env_var)
            if current_raw is None:
                continue
            try:
                desired_port = int(current_raw)
            except ValueError:
                service_ok = False
                service_changes.append(f"{spec.env_var}=invalid({current_raw})")
                break

            resolved_port = find_available_port(desired_port, spec.protocols, reserved, host_used)
            if resolved_port is None:
                service_ok = False
                service_changes.append(f"{spec.env_var}=unresolved({desired_port})")
                break

            for proto in spec.protocols:
                reserved[proto].add(resolved_port)
                service_reservations.append((proto, resolved_port))
            if resolved_port != desired_port:
                values[spec.env_var] = str(resolved_port)
                service_changes.append(f"{spec.env_var}:{desired_port}->{resolved_port}")

        if not service_ok:
            disabled.append(service)
            for proto, port in service_reservations:
                reserved[proto].discard(port)
            continue

        if service_changes:
            changes.append(f"{service}: " + ", ".join(service_changes))
        resolved_services.append(service)

    values["ENABLED_SERVICES"] = ",".join(resolved_services)
    if "ENABLED_SERVICES" not in order:
        order.insert(0, "ENABLED_SERVICES")

    resolved_set = set(resolved_services)
    allowed_fail2ban = [service for service in fail2ban_services if service in resolved_set]
    values["FAIL2BAN_SERVICES"] = ",".join(allowed_fail2ban)
    if "FAIL2BAN_SERVICES" not in order:
        order.insert(1, "FAIL2BAN_SERVICES")

    write_env_file(output_path, order, values)

    if not args.quiet:
        print(f"Runtime env generated: {output_path}")
        if changes:
            print("Resolved port conflicts:")
            for line in changes:
                print(f"  - {line}")
        else:
            print("No port conflicts detected.")
        if disabled:
            print("Disabled services (unresolved ports):")
            for service in disabled:
                print(f"  - {service}")
        print(f"Enabled services: {','.join(resolved_services)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
