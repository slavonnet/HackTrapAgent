#!/usr/bin/env python3
import argparse
import select
import socket
import threading
from datetime import datetime, timezone

BUFFER_SIZE = 65536
MAX_LINE_LENGTH = 8192
MAX_AUTH_ATTEMPTS = 6
IDLE_TIMEOUT_SECONDS = 90


class ProxyLogger:
    def __init__(self, path: str) -> None:
        self._path = path
        self._lock = threading.Lock()

    def log(self, message: str) -> None:
        timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")
        line = f"{timestamp} memcached-proxy[{threading.get_native_id()}]: {message}\n"
        with self._lock:
            with open(self._path, "a", encoding="utf-8") as handle:
                handle.write(line)


def recv_line(conn: socket.socket, pending: bytes) -> tuple[bytes | None, bytes]:
    while b"\n" not in pending:
        chunk = conn.recv(BUFFER_SIZE)
        if not chunk:
            return None, pending
        pending += chunk
        if len(pending) > MAX_LINE_LENGTH:
            return None, b""
    line, pending = pending.split(b"\n", 1)
    return line.rstrip(b"\r"), pending


def send_line(conn: socket.socket, line: str) -> None:
    conn.sendall(f"{line}\r\n".encode("utf-8"))


def sanitize_value(raw: str, fallback: str) -> str:
    value = raw.strip().replace(" ", "_")
    return value if value else fallback


def proxy_streams(client: socket.socket, backend: socket.socket) -> None:
    sockets = [client, backend]
    while True:
        readable, _, _ = select.select(sockets, [], [], IDLE_TIMEOUT_SECONDS)
        if not readable:
            return
        for source in readable:
            data = source.recv(BUFFER_SIZE)
            if not data:
                return
            destination = backend if source is client else client
            destination.sendall(data)


def handle_client(
    client: socket.socket,
    backend_host: str,
    backend_port: int,
    auth_user: str,
    auth_password: str,
    logger: ProxyLogger,
) -> None:
    try:
        peer_ip = client.getpeername()[0]
    except OSError:
        peer_ip = "0.0.0.0"

    client.settimeout(IDLE_TIMEOUT_SECONDS)
    pending = b""
    auth_attempts = 0

    try:
        send_line(client, "ERROR authentication required")
        while True:
            line_bytes, pending = recv_line(client, pending)
            if line_bytes is None:
                return

            command = line_bytes.decode("utf-8", errors="replace").strip()
            if not command:
                continue

            parts = command.split(maxsplit=2)
            verb = parts[0].lower()
            if verb != "auth":
                logger.log(f"AUTH_REQUIRED rip={peer_ip} command={sanitize_value(verb, 'unknown')}")
                send_line(client, "CLIENT_ERROR please authenticate using auth <user> <password>")
                continue

            if len(parts) < 3:
                send_line(client, "CLIENT_ERROR usage: auth <user> <password>")
                continue

            user = parts[1]
            password = parts[2]
            if user == auth_user and password == auth_password:
                logger.log(f"AUTH_SUCCESS rip={peer_ip} user={sanitize_value(user, 'unknown')}")
                send_line(client, "OK")
                break

            auth_attempts += 1
            logger.log(f"AUTH_FAILED rip={peer_ip} user={sanitize_value(user, 'unknown')}")
            send_line(client, "CLIENT_ERROR authentication failed")
            if auth_attempts >= MAX_AUTH_ATTEMPTS:
                return

        with socket.create_connection((backend_host, backend_port), timeout=IDLE_TIMEOUT_SECONDS) as backend:
            backend.settimeout(IDLE_TIMEOUT_SECONDS)
            if pending:
                backend.sendall(pending)
            proxy_streams(client, backend)
    except (OSError, ConnectionError):
        return
    finally:
        try:
            client.close()
        except OSError:
            pass


def main() -> None:
    parser = argparse.ArgumentParser(description="Memcached auth-gated proxy")
    parser.add_argument("--listen-host", default="0.0.0.0")
    parser.add_argument("--listen-port", type=int, default=11211)
    parser.add_argument("--backend-host", default="127.0.0.1")
    parser.add_argument("--backend-port", type=int, default=11212)
    parser.add_argument("--auth-user", required=True)
    parser.add_argument("--auth-password", required=True)
    parser.add_argument("--log-file", required=True)
    args = parser.parse_args()

    logger = ProxyLogger(args.log_file)

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((args.listen_host, args.listen_port))
    server.listen()

    try:
        while True:
            client, _ = server.accept()
            thread = threading.Thread(
                target=handle_client,
                args=(
                    client,
                    args.backend_host,
                    args.backend_port,
                    args.auth_user,
                    args.auth_password,
                    logger,
                ),
                daemon=True,
            )
            thread.start()
    finally:
        server.close()


if __name__ == "__main__":
    main()
