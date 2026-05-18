#!/usr/bin/env python3
import datetime
import os
import socket


def utc_timestamp() -> str:
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def main() -> None:
    listen_port = int(os.environ.get("NTP_LISTEN_PORT", "123"))
    log_file = os.environ.get("NTP_LOG_FILE", "/var/log/ntp/ntp.log")

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(("0.0.0.0", listen_port))

    with open(log_file, "a", encoding="utf-8", buffering=1) as stream:
        while True:
            _, (source_ip, _) = sock.recvfrom(2048)
            stream.write(f"{utc_timestamp()} ntp-honeypot denied packet from {source_ip}\n")


if __name__ == "__main__":
    main()
