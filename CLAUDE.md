# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A pure bash GitHub Action (composite, no Docker) that scans codebases for TLS configuration anti-patterns across Go, Python, Node.js/TypeScript, C++, Java, Rust, Ruby, PHP, C#, and Kotlin using grep-based regex pattern matching.

## Commands

```bash
# Run all unit tests
bash tests/run_tests.sh

# Run individual test suites
bash tests/test_scanner.sh
bash tests/test_config.sh
bash tests/test_custom_patterns.sh
bash tests/test_detect.sh
bash tests/test_incremental.sh
bash tests/test_baseline.sh
bash tests/test_utils.sh
bash tests/test_annotations.sh
bash tests/test_summary.sh
bash tests/test_sarif.sh
bash tests/test_report.sh
bash tests/test_docs.sh
bash tests/test_integration.sh

# Check formatting (shfmt: go install mvdan.cc/sh/v3/cmd/shfmt@latest)
shfmt -d -i 0 -ci .

# Fix formatting
shfmt -w -i 0 -ci .

# Static analysis
shellcheck -S warning entrypoint.sh lib/*.sh patterns/*.sh tests/*.sh
```

## Architecture

Pipeline orchestrated by `entrypoint.sh`:

1. **Config** (`lib/config.sh`) — Pure bash YAML parser; merges inputs > config file > defaults
2. **Detect** (`lib/detect.sh`) — Auto-detects languages from file markers (go.mod, package.json, etc.)
3. **Scan** (`lib/scanner.sh`) — Grep-based pattern matching using definitions from `patterns/*.sh`; optional baseline filtering (`lib/baseline.sh`) suppresses findings already present in a SARIF file
4. **Output** — GitHub annotations (`lib/annotations.sh`), job summary markdown (`lib/summary.sh`), SARIF JSON (`lib/sarif.sh`, requires `jq`), CSV/JSON reports (`lib/report.sh`). Shared helpers live in `lib/utils.sh`.

Findings accumulate in a global `FINDINGS` array as pipe-delimited strings: `"id|severity|name|description|file|line|match"`

Pattern files (`patterns/{go,python,nodejs,cpp,java,rust,ruby,php,csharp,kotlin}.sh`) define arrays of `"id|severity|name|description|regex"` entries. Severity levels: CRITICAL (cert verification disabled), HIGH (weak TLS versions), MEDIUM (prevents TLS 1.3), INFO (PQC, deprecated features).

## Conventions

- All scripts use `#!/usr/bin/env bash` with `set -euo pipefail`
- Global variables are ALL_CAPS; functions are snake_case
- Formatting enforced: `shfmt -i 0 -ci` (tab indentation, case statement indent)
- Must pass ShellCheck (severity: warning) and shfmt
- Tests use custom assertions in `tests/run_tests.sh`: `assert_equals`, `assert_contains`, `assert_greater_than`

## Adding New Language Patterns

1. Create `patterns/<lang>.sh` with a `<LANG>_PATTERNS` array (use `# shellcheck disable=SC2034`)
2. Add language detection in `lib/detect.sh`
3. Add file extensions in `lib/scanner.sh`:
   - `build_include_flags()` — Source file extensions
   - `build_test_exclude_flags()` — Test file patterns
   - `build_lang_exclude_dirs()` — Language-specific directories to skip
4. Add case for the patterns variable in `scan_language()`
5. Create `testdata/<lang>/` with sample files triggering each pattern
6. Add scanner and detection tests in `tests/`
7. Add remediation entries in `docs/patterns.md` (summary table row + detail section with insecure/secure examples)
