#!/usr/bin/env python3

import base64
import datetime
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


LOG_PATH = os.environ.get("ELASTICSEARCH_LOG_PATH", "/var/log/elasticsearch/elasticsearch.log")
LISTEN_PORT = int(os.environ.get("ELASTICSEARCH_LISTEN_PORT", "9200"))
EXPECTED_USER = os.environ.get("ELASTICSEARCH_HONEYPOT_USER", "trap")
EXPECTED_PASSWORD = os.environ.get("ELASTICSEARCH_HONEYPOT_PASSWORD", "")


def log_line(message: str) -> None:
    timestamp = datetime.datetime.now(datetime.timezone.utc).isoformat()
    with open(LOG_PATH, "a", encoding="utf-8") as log_file:
        log_file.write(f"{timestamp} {message}\n")


def parse_basic_auth(header_value: str | None) -> tuple[str, str] | None:
    if not header_value:
        return None
    if not header_value.startswith("Basic "):
        return None

    encoded_part = header_value[6:].strip()
    try:
        decoded_bytes = base64.b64decode(encoded_part, validate=True)
        decoded_text = decoded_bytes.decode("utf-8")
    except (ValueError, UnicodeDecodeError):
        return None

    if ":" not in decoded_text:
        return None
    username, password = decoded_text.split(":", 1)
    return username, password


class ElasticsearchLikeHandler(BaseHTTPRequestHandler):
    server_version = "elasticsearch/8.0.0"

    def log_message(self, format: str, *args: object) -> None:
        return

    def _json_response(self, status_code: int, payload: dict) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _client_ip(self) -> str:
        return self.client_address[0]

    def _authenticate(self) -> tuple[bool, str]:
        credentials = parse_basic_auth(self.headers.get("Authorization"))
        if credentials is None:
            return False, "-"

        username, password = credentials
        if username == EXPECTED_USER and password == EXPECTED_PASSWORD:
            return True, username
        return False, username or "-"

    def _handle_unauthorized(self, presented_user: str) -> None:
        client_ip = self._client_ip()
        log_line(
            "elasticsearch_auth_failed "
            f"src={client_ip} user={presented_user} method={self.command} path={self.path}"
        )

        payload = {
            "error": {
                "root_cause": [
                    {
                        "type": "security_exception",
                        "reason": "unable to authenticate user",
                    }
                ],
                "type": "security_exception",
                "reason": "unable to authenticate user",
            },
            "status": 401,
        }
        body = json.dumps(payload).encode("utf-8")
        self.send_response(401)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("WWW-Authenticate", 'Basic realm="security" charset="UTF-8"')
        self.end_headers()
        self.wfile.write(body)

    def _handle_authorized(self, authenticated_user: str) -> None:
        client_ip = self._client_ip()
        request_body = ""
        body_length = int(self.headers.get("Content-Length", "0") or "0")
        if body_length > 0:
            request_body = self.rfile.read(body_length).decode("utf-8", errors="replace")

        if self.path == "/" and self.command == "GET":
            payload = {
                "name": "hacktrap-es-node",
                "cluster_name": "hacktrap-es-cluster",
                "version": {"number": "8.0.0"},
                "tagline": "You Know, for Search",
            }
            self._json_response(200, payload)
            log_line(
                "elasticsearch_request "
                f"src={client_ip} user={authenticated_user} method={self.command} path={self.path}"
            )
            return

        if self.path == "/_search" and self.command in {"GET", "POST"}:
            payload = {
                "took": 1,
                "timed_out": False,
                "hits": {"total": {"value": 0, "relation": "eq"}, "hits": []},
            }
            self._json_response(200, payload)
            truncated_body = request_body[:256].replace("\n", " ")
            log_line(
                "elasticsearch_query "
                f"src={client_ip} user={authenticated_user} method={self.command} path={self.path} "
                f"body={truncated_body}"
            )
            return

        payload = {
            "result": "accepted",
            "path": self.path,
            "method": self.command,
        }
        self._json_response(200, payload)
        log_line(
            "elasticsearch_request "
            f"src={client_ip} user={authenticated_user} method={self.command} path={self.path}"
        )

    def do_GET(self) -> None:
        authenticated, presented_user = self._authenticate()
        if not authenticated:
            self._handle_unauthorized(presented_user)
            return
        self._handle_authorized(presented_user)

    def do_POST(self) -> None:
        authenticated, presented_user = self._authenticate()
        if not authenticated:
            self._handle_unauthorized(presented_user)
            return
        self._handle_authorized(presented_user)

    def do_PUT(self) -> None:
        authenticated, presented_user = self._authenticate()
        if not authenticated:
            self._handle_unauthorized(presented_user)
            return
        self._handle_authorized(presented_user)


def main() -> None:
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    log_line(
        "Elasticsearch honeypot started "
        f"port={LISTEN_PORT} user={EXPECTED_USER}"
    )
    server = ThreadingHTTPServer(("0.0.0.0", LISTEN_PORT), ElasticsearchLikeHandler)
    server.serve_forever()


if __name__ == "__main__":
    main()
