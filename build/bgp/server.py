#!/usr/bin/env python3

import datetime
import ipaddress
import os
import socket
from typing import Iterable


LOG_PATH = os.environ.get("BGP_LOG_PATH", "/var/log/bgp/bgp.log")
PEERS_FILE = os.environ.get("BGP_PEERS_FILE", "/opt/hacktrap/etc/bgp/peers.conf")
ALLOWED_PEERS_ENV = os.environ.get("BGP_ALLOWED_PEERS", "")
LISTEN_PORT = int(os.environ.get("BGP_LISTEN_PORT", "179"))


def parse_peers(raw_values: Iterable[str]) -> set[str]:
    peers: set[str] = set()
    for value in raw_values:
        candidate = value.strip()
        if not candidate:
            continue
        try:
            peers.add(str(ipaddress.ip_address(candidate)))
        except ValueError:
            continue
    return peers


def load_configured_peers() -> set[str]:
    peers = set()
    if os.path.isfile(PEERS_FILE):
        with open(PEERS_FILE, "r", encoding="utf-8") as peers_file:
            file_values: list[str] = []
            for line in peers_file:
                line = line.split("#", 1)[0]
                file_values.extend(line.replace(",", " ").split())
            peers.update(parse_peers(file_values))

    peers.update(parse_peers(ALLOWED_PEERS_ENV.replace(",", " ").split()))
    return peers


def log_line(message: str) -> None:
    timestamp = datetime.datetime.now(datetime.timezone.utc).isoformat()
    with open(LOG_PATH, "a", encoding="utf-8") as log_file:
        log_file.write(f"{timestamp} {message}\n")


def main() -> None:
    configured_peers = load_configured_peers()
    log_line(
        "BGP honeypot started on port "
        f"{LISTEN_PORT}; configured peers loaded: {len(configured_peers)}"
    )

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server_socket:
        server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server_socket.bind(("0.0.0.0", LISTEN_PORT))
        server_socket.listen(128)

        while True:
            connection, address = server_socket.accept()
            peer_ip = address[0]
            if peer_ip in configured_peers:
                log_line(f"BGP connection from configured peer {peer_ip}")
            else:
                log_line(f"BGP connection from unconfigured peer {peer_ip}")
            connection.close()


if __name__ == "__main__":
    main()
