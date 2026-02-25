# TLS Config Lint

A bash-based GitHub Action that scans codebases for TLS configuration anti-patterns across Go, Python, Node.js/TypeScript, and C++.

## Project Structure

- `entrypoint.sh` — Main orchestrator
- `action.yml` — GitHub Actions composite action definition
- `lib/` — Modular bash libraries:
  - `utils.sh` — Severity comparison, logging, string utilities
  - `config.sh` — Pure bash YAML config parser
  - `detect.sh` — Language auto-detection
  - `scanner.sh` — Core grep-based scanning engine
  - `annotations.sh` — GitHub Actions annotation emitter
  - `summary.sh` — Job summary markdown generator
  - `sarif.sh` — SARIF 2.1.0 JSON generator (requires `jq`)
- `patterns/` — Language-specific pattern definitions (`go.sh`, `python.sh`, `nodejs.sh`, `cpp.sh`)
- `tests/` — Unit tests (`run_tests.sh`, `test_scanner.sh`, `test_detect.sh`, `test_config.sh`)
- `testdata/` — Sample files with intentional TLS anti-patterns for testing

## Commands

```bash
# Run tests
bash tests/run_tests.sh

# Check formatting
shfmt -d -i 0 -ci .

# Fix formatting
shfmt -w -i 0 -ci .

# Lint
shellcheck lib/*.sh patterns/*.sh tests/*.sh entrypoint.sh
```

## Development Guidelines

- **Pure bash** — No external runtime dependencies (except `jq` for optional SARIF output)
- All scripts must pass **ShellCheck** (severity: warning) and **shfmt** formatting (`-i 0 -ci`)
- Pattern format is pipe-delimited: `id|severity|name|description|regex`
- Severities: `CRITICAL`, `HIGH`, `MEDIUM`, `INFO`
- Tests use the custom assertion framework in `tests/run_tests.sh` (`assert_equals`, `assert_contains`, `assert_greater_than`)

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

## PR Guidelines

- All PRs must pass CI (ShellCheck, shfmt, unit tests, self-test)
- Add tests for new functionality
- Keep the linter dependency-free (pure bash)
