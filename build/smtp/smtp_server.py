#!/usr/bin/env python3
import argparse
import base64
import binascii
import os
from datetime import datetime, timezone
from pathlib import Path
import socketserver


class SmtpHandler(socketserver.StreamRequestHandler):
    def _write_line(self, payload: str) -> None:
        self.wfile.write(payload.encode("utf-8"))
        self.wfile.flush()

    def _read_line(self) -> str:
        raw = self.rfile.readline(4096)
        if not raw:
            return ""
        return raw.decode("utf-8", errors="ignore").strip()

    def _decode_b64(self, value: str) -> str:
        try:
            decoded = base64.b64decode(value.encode("utf-8"), validate=True)
        except (ValueError, binascii.Error):
            return ""
        return decoded.decode("utf-8", errors="ignore")

    def _log_failure(self, user: str) -> None:
        ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        line = f"{ts} SMTP_AUTH_FAILED user={user} rip={self.client_address[0]}\n"
        with open(self.server.log_file, "a", encoding="utf-8") as handle:  # type: ignore[attr-defined]
            handle.write(line)

    def handle(self) -> None:
        expected_user = self.server.runtime_user  # type: ignore[attr-defined]
        expected_password = self.server.runtime_password  # type: ignore[attr-defined]
        self._write_line("220 HackTrap SMTP ready\r\n")

        while True:
            line = self._read_line()
            if not line:
                return

            upper = line.upper()
            if upper.startswith("EHLO") or upper.startswith("HELO"):
                self._write_line("250-HackTrap SMTP\r\n")
                self._write_line("250-AUTH LOGIN\r\n")
                self._write_line("250 HELP\r\n")
                continue

            if upper.startswith("AUTH LOGIN"):
                self._write_line("334 VXNlcm5hbWU6\r\n")
                user_b64 = self._read_line()
                if not user_b64:
                    return
                user = self._decode_b64(user_b64)

                self._write_line("334 UGFzc3dvcmQ6\r\n")
                password_b64 = self._read_line()
                if not password_b64:
                    return
                password = self._decode_b64(password_b64)

                if user == expected_user and password == expected_password:
                    self._write_line("235 2.7.0 Authentication successful\r\n")
                else:
                    self._log_failure(user or "unknown")
                    self._write_line("535 5.7.8 Authentication credentials invalid\r\n")
                continue

            if upper.startswith("QUIT"):
                self._write_line("221 2.0.0 Bye\r\n")
                return

            self._write_line("500 5.5.2 Command not recognized\r\n")


class ThreadedTcpServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    allow_reuse_address = True


def main() -> None:
    parser = argparse.ArgumentParser(description="Minimal SMTP honeypot server")
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=25)
    parser.add_argument("--log-file", required=True)
    args = parser.parse_args()

    runtime_user = os.environ.get("SMTP_RUNTIME_USER", "trap")
    runtime_password = os.environ.get("SMTP_RUNTIME_PASSWORD", "")
    if not runtime_password:
        raise RuntimeError("SMTP_RUNTIME_PASSWORD is required")

    log_path = Path(args.log_file)
    log_path.parent.mkdir(parents=True, exist_ok=True)
    log_path.touch(exist_ok=True)

    with ThreadedTcpServer((args.host, args.port), SmtpHandler) as server:
        server.log_file = str(log_path)
        server.runtime_user = runtime_user
        server.runtime_password = runtime_password
        server.serve_forever()


if __name__ == "__main__":
    main()
