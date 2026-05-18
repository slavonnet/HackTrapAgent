#!/usr/bin/env python3
"""Benchmark all enabled honeypot services and generate a resource table."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Iterable, List


SIZE_UNITS = {
    "b": 1,
    "kb": 1000,
    "mb": 1000**2,
    "gb": 1000**3,
    "tb": 1000**4,
    "kib": 1024,
    "mib": 1024**2,
    "gib": 1024**3,
    "tib": 1024**4,
}


@dataclass
class ServiceMetrics:
    service: str
    container_id: str
    image_size_bytes: int = 0
    peak_memory_bytes: float = 0.0
    cpu_core_seconds: float = 0.0
    memory_accounting_available: bool = False


def run(
    cmd: List[str],
    *,
    capture_output: bool = True,
    check: bool = True,
    timeout: float | None = None,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        check=check,
        capture_output=capture_output,
        text=True,
        timeout=timeout,
    )


def resolve_docker_cmd() -> List[str]:
    try:
        run(["docker", "info"])
        return ["docker"]
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass

    try:
        run(["sudo", "-n", "docker", "info"])
        return ["sudo", "docker"]
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass

    raise RuntimeError("Cannot access docker daemon. Start docker and/or allow sudo docker access.")


def parse_services_env(config_path: Path) -> List[str]:
    enabled_services = ""
    for line in config_path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped.startswith("ENABLED_SERVICES="):
            enabled_services = stripped.split("=", 1)[1]
            break
    services = [item.strip() for item in enabled_services.split(",") if item.strip()]
    if not services:
        raise RuntimeError("ENABLED_SERVICES is empty in config/services.env.")
    return services


def parse_size_to_bytes(size_str: str) -> float:
    text = size_str.strip()
    if not text:
        return 0.0

    match = re.match(r"^([0-9]*\.?[0-9]+)\s*([A-Za-z]+)?$", text)
    if not match:
        raise ValueError(f"Unsupported size format: {size_str}")

    value = float(match.group(1))
    unit = (match.group(2) or "B").lower()
    multiplier = SIZE_UNITS.get(unit)
    if multiplier is None:
        raise ValueError(f"Unsupported size unit: {unit}")
    return value * multiplier


def format_bytes(size_bytes: float) -> str:
    value = float(size_bytes)
    for unit in ("B", "KiB", "MiB", "GiB", "TiB"):
        if value < 1024 or unit == "TiB":
            if unit == "B":
                return f"{int(value)} {unit}"
            return f"{value:.2f} {unit}"
        value /= 1024
    return f"{value:.2f} TiB"


def parse_compose_ports(compose_config: Dict[str, object], services: Iterable[str]) -> Dict[str, str]:
    result: Dict[str, str] = {}
    service_map = compose_config.get("services", {})
    for service in services:
        raw_ports = service_map.get(service, {}).get("ports", [])  # type: ignore[union-attr]
        formatted: List[str] = []
        for item in raw_ports:
            if isinstance(item, str):
                formatted.append(item)
                continue
            if not isinstance(item, dict):
                continue
            published = str(item.get("published", item.get("target", ""))).strip()
            protocol = str(item.get("protocol", "tcp")).strip()
            if not published:
                continue
            formatted.append(f"{published}/{protocol}")
        result[service] = ", ".join(formatted) if formatted else "-"
    return result


def service_doc_link(project_root: Path, service: str) -> str:
    doc_path = project_root / "docs" / "services" / f"{service}.md"
    if doc_path.exists():
        return f"[{service}](docs/services/{service}.md)"
    return service


def main() -> int:
    parser = argparse.ArgumentParser(description="Run a 5-minute benchmark for enabled services.")
    parser.add_argument("--duration-seconds", type=int, default=300, help="Benchmark duration in seconds.")
    parser.add_argument("--sample-interval-seconds", type=float, default=1.0, help="Sampling interval in seconds.")
    parser.add_argument(
        "--stats-timeout-seconds",
        type=float,
        default=5.0,
        help="Per-sample timeout for docker stats calls.",
    )
    parser.add_argument("--build", action="store_true", help="Build images before benchmark start.")
    parser.add_argument("--output-file", default="", help="Output markdown report path.")
    parser.add_argument("--output-csv", default="", help="Optional output CSV report path.")
    args = parser.parse_args()

    if args.duration_seconds <= 0:
        raise RuntimeError("--duration-seconds must be greater than 0.")
    if args.sample_interval_seconds <= 0:
        raise RuntimeError("--sample-interval-seconds must be greater than 0.")
    if args.stats_timeout_seconds <= 0:
        raise RuntimeError("--stats-timeout-seconds must be greater than 0.")

    project_root = Path(__file__).resolve().parent.parent
    config_file = Path(os.environ.get("CONFIG_FILE", project_root / "config/services.env"))
    compose_file = Path(os.environ.get("COMPOSE_FILE", project_root / "docker-compose.yml"))
    output_dir = project_root / "reports" / "benchmarks"
    output_dir.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    output_file = Path(args.output_file) if args.output_file else output_dir / f"services_benchmark_{timestamp}.md"
    output_csv = Path(args.output_csv) if args.output_csv else output_dir / f"services_benchmark_{timestamp}.csv"

    docker_cmd = resolve_docker_cmd()
    services = parse_services_env(config_file)

    compose_prefix = [
        *docker_cmd,
        "compose",
        "--env-file",
        str(config_file),
        "-f",
        str(compose_file),
    ]

    startup_services = ["fail2ban", *services]
    up_cmd = [*compose_prefix, "up", "-d"]
    if args.build:
        up_cmd.append("--build")
    up_cmd.extend(startup_services)

    print(f"Starting benchmark stack: {', '.join(startup_services)}")
    run(up_cmd, capture_output=False)

    try:
        print("Resolving compose configuration...")
        compose_config_json = run([*compose_prefix, "config", "--format", "json", *startup_services]).stdout
        compose_config = json.loads(compose_config_json)
        ports_by_service = parse_compose_ports(compose_config, services)

        metrics_by_service: Dict[str, ServiceMetrics] = {}
        container_to_service: Dict[str, str] = {}
        container_ids: List[str] = []
        for service in services:
            container_id = run([*compose_prefix, "ps", "-q", service]).stdout.strip()
            if not container_id:
                raise RuntimeError(f"Container for service '{service}' is not running.")
            metrics_by_service[service] = ServiceMetrics(service=service, container_id=container_id)
            container_to_service[container_id] = service
            container_to_service[container_id[:12]] = service
            container_ids.append(container_id)
        print(
            f"Collecting stats for {len(container_ids)} containers "
            f"for {args.duration_seconds}s with interval {args.sample_interval_seconds}s..."
        )

        next_tick = time.monotonic()
        end_at = time.monotonic() + args.duration_seconds
        while time.monotonic() < end_at:
            next_tick += args.sample_interval_seconds
            try:
                stats_output = run(
                    [
                        *docker_cmd,
                        "stats",
                        "--no-stream",
                        "--format",
                        "{{.ID}}|{{.CPUPerc}}|{{.MemUsage}}",
                        *container_ids,
                    ],
                    timeout=args.stats_timeout_seconds,
                ).stdout
            except subprocess.TimeoutExpired:
                print(
                    f"WARNING: docker stats sample timed out after {args.stats_timeout_seconds}s; "
                    "skipping this sample."
                )
                stats_output = ""
            for raw_line in stats_output.splitlines():
                line = raw_line.strip()
                if not line:
                    continue
                parts = line.split("|", 2)
                if len(parts) != 3:
                    continue
                container_id, cpu_perc_raw, mem_usage_raw = parts
                service = container_to_service.get(container_id)
                if service is None:
                    continue
                cpu_percent = float(cpu_perc_raw.strip().replace("%", "").replace(",", ".") or "0")
                if "/" in mem_usage_raw:
                    mem_used_raw, mem_limit_raw = [part.strip() for part in mem_usage_raw.split("/", 1)]
                else:
                    mem_used_raw = mem_usage_raw.strip()
                    mem_limit_raw = "0B"
                mem_used_bytes = parse_size_to_bytes(mem_used_raw)
                mem_limit_bytes = parse_size_to_bytes(mem_limit_raw)

                metrics = metrics_by_service[service]
                metrics.cpu_core_seconds += (cpu_percent / 100.0) * args.sample_interval_seconds
                if mem_limit_bytes > 0:
                    metrics.memory_accounting_available = True
                if metrics.memory_accounting_available and mem_used_bytes > metrics.peak_memory_bytes:
                    metrics.peak_memory_bytes = mem_used_bytes

            sleep_for = max(0.0, next_tick - time.monotonic())
            if sleep_for > 0:
                time.sleep(sleep_for)

        print("Collecting image sizes...")
        for service, metrics in metrics_by_service.items():
            image_id = run([*docker_cmd, "inspect", "--format", "{{.Image}}", metrics.container_id]).stdout.strip()
            size_raw = run([*docker_cmd, "image", "inspect", "--format", "{{.Size}}", image_id]).stdout.strip()
            metrics.image_size_bytes = int(size_raw)

        lines = [
            "# Services benchmark report",
            "",
            f"- Generated at (UTC): {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S')}",
            f"- Duration: {args.duration_seconds} seconds",
            f"- Sample interval: {args.sample_interval_seconds} seconds",
            "",
            "| Port | Service (docs) | Image size | Peak memory | CPU time (core-seconds) |",
            "| --- | --- | --- | --- | --- |",
        ]

        csv_lines = ["service,ports,image_size_bytes,peak_memory_bytes,cpu_core_seconds"]
        missing_memory_accounting = False
        for service in services:
            metrics = metrics_by_service[service]
            ports = ports_by_service.get(service, "-")
            if metrics.memory_accounting_available:
                peak_memory_display = format_bytes(metrics.peak_memory_bytes)
                peak_memory_csv = str(int(metrics.peak_memory_bytes))
            else:
                peak_memory_display = "n/a"
                peak_memory_csv = ""
                missing_memory_accounting = True
            lines.append(
                f"| {ports} | {service_doc_link(project_root, service)} | "
                f"{format_bytes(metrics.image_size_bytes)} | "
                f"{peak_memory_display} | "
                f"{metrics.cpu_core_seconds:.2f} |"
            )
            csv_lines.append(
                f"{service},\"{ports}\",{metrics.image_size_bytes},{peak_memory_csv},{metrics.cpu_core_seconds:.6f}"
            )

        if missing_memory_accounting:
            lines.insert(6, "> Note: Peak memory is marked `n/a` when Docker memory accounting is unavailable on the host.")
            lines.insert(7, "")

        output_file.parent.mkdir(parents=True, exist_ok=True)
        output_file.write_text("\n".join(lines) + "\n", encoding="utf-8")
        output_csv.parent.mkdir(parents=True, exist_ok=True)
        output_csv.write_text("\n".join(csv_lines) + "\n", encoding="utf-8")
        print(f"Benchmark markdown report: {output_file}")
        print(f"Benchmark CSV report: {output_csv}")
    finally:
        print("Stopping benchmark stack...")
        run([*compose_prefix, "stop", *startup_services], capture_output=False, check=False)
        run([*compose_prefix, "rm", "-fsv", *startup_services], capture_output=False, check=False)
        run([*compose_prefix, "down", "-v", "--remove-orphans"], capture_output=False, check=False)

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # pylint: disable=broad-except
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
