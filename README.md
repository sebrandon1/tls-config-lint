# tls-config-lint

A GitHub Action that scans your codebase for TLS configuration anti-patterns across Go, Python, Node.js/TypeScript, and C++ projects. Uses a binary **pass/fail** model: any hardcoded TLS configuration that doesn't dynamically inherit from the cluster's centralized `tlsSecurityProfile` is a **FAIL**.

This approach aligns with [CNF-21745](https://issues.redhat.com/browse/CNF-21745) acceptance criteria for OCP 4.22 TLS compliance.

## Features

- Detects 23 TLS security anti-patterns across 4 languages
- Binary pass/fail model (no severity thresholds)
- Inline PR annotations on affected lines
- Job summary with findings table
- Optional SARIF output for GitHub Code Scanning integration
- Per-pattern suppression via pattern IDs
- Auto-detection of project languages
- Composite action (no Docker build overhead)

## Quick Start

```yaml
- uses: sebrandon1/tls-config-lint@v2
```

## Usage Examples

### Basic (default settings)

```yaml
name: TLS Lint
on: [push, pull_request]
jobs:
  tls-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: sebrandon1/tls-config-lint@v2
```

### With SARIF for Code Scanning

```yaml
- uses: sebrandon1/tls-config-lint@v2
  with:
    sarif-output: tls-lint.sarif
    fail-on-findings: false
- uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: tls-lint.sarif
  if: always()
```

### Specific languages only

```yaml
- uses: sebrandon1/tls-config-lint@v2
  with:
    languages: go,python
```

### Exclude directories and patterns

```yaml
- uses: sebrandon1/tls-config-lint@v2
  with:
    exclude-dirs: test/fixtures,examples/insecure
    exclude-patterns: insecure-skip-verify,hardcoded-tls-config
```

## Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `languages` | `auto` | Comma-separated: `go,python,nodejs,cpp` or `auto` to detect |
| `exclude-dirs` | _(empty)_ | Additional dirs to exclude (comma-separated) |
| `exclude-patterns` | _(empty)_ | Pattern IDs to suppress (comma-separated) |
| `config-file` | `.tls-config-lint.yml` | Path to optional repo config file |
| `scan-path` | `.` | Directory to scan |
| `fail-on-findings` | `true` | Whether to fail CI when findings are detected |
| `sarif-output` | _(empty)_ | Path to write SARIF file (empty = disabled) |

## Outputs

| Output | Description |
|--------|-------------|
| `findings-count` | Total number of findings |
| `sarif-file` | Path to SARIF file (if generated) |

## Configuration File

Create a `.tls-config-lint.yml` in your repository root for persistent configuration:

```yaml
languages:
  - go
  - python
exclude-dirs:
  - test/fixtures
  - examples/insecure
exclude-patterns:
  - insecure-skip-verify    # Intentional in test helpers
```

Action inputs override config file values. Lists (exclude-dirs, exclude-patterns) are merged (union).

See [`.tls-config-lint.example.yml`](.tls-config-lint.example.yml) for a full example.

## Detected Patterns

All patterns are **FAIL** findings. Any match indicates a TLS configuration that should be reviewed.

### Go (6 patterns)

| ID | Description |
|----|-------------|
| `insecure-skip-verify` | `InsecureSkipVerify: true` disables certificate verification |
| `min-version-tls10` | `MinVersion` set to TLS 1.0 |
| `min-version-tls11` | `MinVersion` set to TLS 1.1 |
| `max-version-tls10` | `MaxVersion` set to TLS 1.0 |
| `max-version-tls11` | `MaxVersion` set to TLS 1.1 |
| `hardcoded-tls-config` | Hardcoded `tls.Config{}` not using centralized `tlsSecurityProfile` |

### Python (6 patterns)

| ID | Description |
|----|-------------|
| `verify-false` | `verify=False` disables certificate verification |
| `cert-none` | `ssl.CERT_NONE` disables verification |
| `create-unverified-context` | `_create_unverified_context()` |
| `check-hostname-false` | `check_hostname = False` |
| `protocol-tlsv1` | Uses `PROTOCOL_TLSv1` (TLS 1.0) |
| `protocol-tlsv11` | Uses `PROTOCOL_TLSv1_1` |

### Node.js/TypeScript (5 patterns)

| ID | Description |
|----|-------------|
| `reject-unauthorized-false` | `rejectUnauthorized: false` |
| `node-tls-reject-unauthorized` | `NODE_TLS_REJECT_UNAUTHORIZED` env var |
| `tlsv1-method` | Uses `TLSv1_method` |
| `tlsv11-method` | Uses `TLSv1_1_method` |
| `min-version-weak` | `minVersion` allows TLS 1.0/1.1 |

### C++ (6 patterns)

| ID | Description |
|----|-------------|
| `ssl-ctx-verify-none` | `SSL_CTX_set_verify` with `SSL_VERIFY_NONE` |
| `ssl-set-verify-none` | `SSL_set_verify` with `SSL_VERIFY_NONE` |
| `tls1-version` | Uses `TLS1_VERSION` (TLS 1.0) |
| `tls11-version` | Uses `TLS1_1_VERSION` |
| `sslv3-method` | Uses `SSLv3_method` |
| `tlsv1-method` | Uses `TLSv1_method` |

## Built-in Exclusions

The following directories are excluded from scanning by default:

- `vendor`, `.git`, `testdata`, `mocks`, `test`, `tests`, `e2e`, `testing`, `mock`, `fakes`, `fixtures`
- Go: `*_test.go` files
- Python: `*_test.py`, `test_*.py`, `conftest.py`, `__pycache__/`, `venv/`, `.venv/`
- Node.js: `*.test.js`, `*.spec.js` (and `.ts`/`.mjs`/`.mts` variants), `node_modules/`, `__tests__/`
- C++: `*_test.cpp`, `*_test.cc`

## Go-Specific: TLSSecurityProfile Noise Reduction

For Go projects, findings for `hardcoded-tls-config` (detecting `tls.Config{}`) are automatically filtered out in files that also reference `TLSSecurityProfile`, since those files are consuming centralized configuration rather than hardcoding TLS settings.

## Migrating from v1

v2 simplifies to a pass/fail model. Key changes:

- **Removed:** `severity-threshold` input (all findings are failures)
- **Removed:** `critical-count`, `high-count`, `medium-count`, `info-count` outputs
- **Removed:** INFO patterns (PQC readiness, curve preferences, deprecated Go options)
- **Removed:** MEDIUM patterns (MaxVersion TLS 1.2 caps)
- **Kept:** `findings-count` output, `fail-on-findings` input, `sarif-file` output

## License

Apache License 2.0 - see [LICENSE](LICENSE) for details.
