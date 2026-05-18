#!/usr/bin/env python3
import datetime
import os
import socket


def utc_timestamp() -> str:
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def classify_action(packet: bytes) -> str:
    if not packet:
        return "unauth-denied-empty-datagram"

    first_byte = packet[0]
    version = (first_byte >> 3) & 0x07
    mode = first_byte & 0x07
    size = len(packet)

    if size < 48:
        return f"unauth-denied-malformed-v{version}-mode{mode}-len{size}"

    if mode == 6:
        opcode = packet[1] & 0x1F
        return f"unauth-denied-mode6-control-opcode-{opcode}"

    if mode == 7:
        request_code = packet[3]
        return f"unauth-denied-mode7-private-request-{request_code}"

    return f"unauth-denied-mode{mode}-request-v{version}"


def main() -> None:
    listen_port = int(os.environ.get("NTP_LISTEN_PORT", "123"))
    log_file = os.environ.get("NTP_LOG_FILE", "/var/log/ntp/ntp.log")

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(("0.0.0.0", listen_port))

    with open(log_file, "a", encoding="utf-8", buffering=1) as stream:
        while True:
            packet, (source_ip, _) = sock.recvfrom(2048)
            action = classify_action(packet)
            stream.write(f"{utc_timestamp()} ntp-honeypot action={action} from {source_ip}\n")


if __name__ == "__main__":
    main()
