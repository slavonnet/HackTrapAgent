# UpdateBenchmark

## Purpose

Run the 5-minute service benchmark and refresh the benchmark table in `README.md`.

## Steps

1. Run benchmark:
   - `./scripts/benchmark_services.sh --duration-seconds 300 --output-file /tmp/benchmark_5min.md --output-csv /tmp/benchmark_5min.csv`
2. Use values from `/tmp/benchmark_5min.md` to update the `README.md` services table.
3. Keep table values numeric-only for size columns:
   - `Image size (MiB)` column: numbers only.
   - `Peak memory (MiB)` column: numbers only (or `n/a`).
4. Keep rounded integer formatting for:
   - `MiB` values in table size columns,
   - `GB` and `GiB` values in `TOTAL` block.
5. Clean temporary artifacts that should not be committed.
6. Commit, push, and update/create PR.

## Expected output format

- Table header must include `Image size (MiB)`.
- Size cells must contain only numbers (no inline `MiB` suffixes).
- `TOTAL` block must use rounded integer `GB`/`GiB` values.
