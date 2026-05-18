#!/usr/bin/env python3
import argparse
import socketserver
from datetime import datetime, timezone
from pathlib import Path
import os


class ImapHandler(socketserver.StreamRequestHandler):
    def _write_line(self, payload: str) -> None:
        self.wfile.write(payload.encode("utf-8"))
        self.wfile.flush()

    def _log_failure(self, user: str) -> None:
        ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        line = f"{ts} IMAP_AUTH_FAILED user=<{user}> rip={self.client_address[0]}\n"
        with open(self.server.log_file, "a", encoding="utf-8") as handle:  # type: ignore[attr-defined]
            handle.write(line)

    def handle(self) -> None:
        expected_user = self.server.runtime_user  # type: ignore[attr-defined]
        expected_password = self.server.runtime_password  # type: ignore[attr-defined]
        self._write_line("* OK HackTrap IMAP ready\r\n")

        while True:
            raw_line = self.rfile.readline(4096)
            if not raw_line:
                return

            line = raw_line.decode("utf-8", errors="ignore").strip()
            if not line:
                continue

            parts = line.split()
            if len(parts) < 2:
                continue

            tag = parts[0]
            command = parts[1].upper()

            if command == "LOGIN" and len(parts) >= 4:
                user = parts[2]
                password = parts[3]
                if user == expected_user and password == expected_password:
                    self._write_line(f"{tag} OK LOGIN completed\r\n")
                else:
                    self._log_failure(user)
                    self._write_line(f"{tag} NO Authentication failed.\r\n")
                continue

            if command == "LOGOUT":
                self._write_line("* BYE Logging out\r\n")
                self._write_line(f"{tag} OK LOGOUT completed\r\n")
                return

            self._write_line(f"{tag} BAD Unsupported command\r\n")


class ThreadedTcpServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    allow_reuse_address = True


def main() -> None:
    parser = argparse.ArgumentParser(description="Minimal IMAP honeypot server")
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=143)
    parser.add_argument("--log-file", required=True)
    args = parser.parse_args()

    runtime_user = os.environ.get("IMAP_RUNTIME_USER", "trap")
    runtime_password = os.environ.get("IMAP_RUNTIME_PASSWORD", "")
    if not runtime_password:
        raise RuntimeError("IMAP_RUNTIME_PASSWORD is required")

    log_path = Path(args.log_file)
    log_path.parent.mkdir(parents=True, exist_ok=True)
    log_path.touch(exist_ok=True)

    with ThreadedTcpServer((args.host, args.port), ImapHandler) as server:
        server.log_file = str(log_path)
        server.runtime_user = runtime_user
        server.runtime_password = runtime_password
        server.serve_forever()


if __name__ == "__main__":
    main()
