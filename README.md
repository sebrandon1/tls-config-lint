# tls-config-lint

A GitHub Action that scans your codebase for TLS configuration anti-patterns and security issues across Go, Python, Node.js/TypeScript, C++, and Java projects.

> **See also:** [tls-compliance-operator](https://github.com/sebrandon1/tls-compliance-operator) — a Kubernetes operator that continuously monitors live TLS endpoints at runtime. Use **tls-config-lint** to catch issues in source code (shift-left) and **tls-compliance-operator** to verify runtime compliance in your cluster.

## Features

- Detects 49 TLS security anti-patterns across 5 languages
- Configurable severity thresholds (critical, high, medium, info)
- Inline PR annotations on affected lines
- Job summary with findings table
- Optional SARIF output for GitHub Code Scanning integration
- Per-pattern suppression via pattern IDs
- Auto-detection of project languages
- Composite action (no Docker build overhead)

## Quick Start

```yaml
- uses: sebrandon1/tls-config-lint@v1
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
      - uses: sebrandon1/tls-config-lint@v1
```

### Custom severity threshold

```yaml
- uses: sebrandon1/tls-config-lint@v1
  with:
    severity-threshold: critical
```

### With SARIF for Code Scanning

```yaml
- uses: sebrandon1/tls-config-lint@v1
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
- uses: sebrandon1/tls-config-lint@v1
  with:
    languages: go,python
```

### Exclude directories and patterns

```yaml
- uses: sebrandon1/tls-config-lint@v1
  with:
    exclude-dirs: test/fixtures,examples/insecure
    exclude-patterns: insecure-skip-verify,hardcoded-tls-config
```

## Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `severity-threshold` | `high` | Minimum severity to cause failure: `critical`, `high`, `medium`, `info` |
| `languages` | `auto` | Comma-separated: `go,python,nodejs,cpp` or `auto` to detect |
| `exclude-dirs` | _(empty)_ | Additional dirs to exclude (comma-separated) |
| `exclude-patterns` | _(empty)_ | Pattern IDs to suppress (comma-separated) |
| `config-file` | `.tls-config-lint.yml` | Path to optional repo config file |
| `scan-path` | `.` | Directory to scan |
| `fail-on-findings` | `true` | Whether to fail CI on findings above threshold |
| `sarif-output` | _(empty)_ | Path to write SARIF file (empty = disabled) |

## Outputs

| Output | Description |
|--------|-------------|
| `findings-count` | Total number of findings |
| `critical-count` | Number of critical findings |
| `high-count` | Number of high findings |
| `medium-count` | Number of medium findings |
| `info-count` | Number of info findings |
| `sarif-file` | Path to SARIF file (if generated) |

## Exit Codes

| Code | Meaning |
|------|---------|
| `0`  | No findings at or above severity threshold |
| `1`  | Findings detected at or above threshold (`fail-on-findings: true`) |
| `2`  | Configuration or validation error (invalid inputs, missing `jq`) |

## Configuration File

Create a `.tls-config-lint.yml` in your repository root for persistent configuration:

```yaml
severity-threshold: high
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

### Go (16 patterns)

| ID | Severity | Description |
|----|----------|-------------|
| `insecure-skip-verify` | CRITICAL | `InsecureSkipVerify: true` disables certificate verification |
| `weak-cipher-rc4` | CRITICAL | RC4 cipher suite (completely broken) |
| `null-cipher` | CRITICAL | NULL cipher suite (no encryption) |
| `min-version-tls10` | HIGH | `MinVersion` set to TLS 1.0 |
| `min-version-tls11` | HIGH | `MinVersion` set to TLS 1.1 |
| `max-version-tls10` | HIGH | `MaxVersion` set to TLS 1.0 |
| `max-version-tls11` | HIGH | `MaxVersion` set to TLS 1.1 |
| `weak-cipher-3des` | HIGH | 3DES/CBC cipher suites |
| `tls-profile-old` | HIGH | Old TLS security profile allows TLS 1.0/1.1 |
| `max-version-tls12` | MEDIUM | `MaxVersion` set to TLS 1.2 (prevents 1.3) |
| `tls-profile-custom` | MEDIUM | Custom TLS security profile needs review |
| `min-version-tls13` | INFO | Forces TLS 1.3 only |
| `prefer-server-cipher-suites` | INFO | Deprecated in Go 1.17+ |
| `curve-preferences` | INFO | Explicit curve configuration |
| `hardcoded-tls-config` | INFO | Hardcoded `tls.Config{}` |
| `pqc-ml-kem` | INFO | Post-Quantum Cryptography adoption |

### Python (11 patterns)

| ID | Severity | Description |
|----|----------|-------------|
| `verify-false` | CRITICAL | `verify=False` disables certificate verification |
| `cert-none` | CRITICAL | `ssl.CERT_NONE` disables verification |
| `create-unverified-context` | CRITICAL | `_create_unverified_context()` |
| `check-hostname-false` | CRITICAL | `check_hostname = False` |
| `protocol-tlsv1` | HIGH | Uses `PROTOCOL_TLSv1` (TLS 1.0) |
| `protocol-tlsv11` | HIGH | Uses `PROTOCOL_TLSv1_1` |
| `weak-cipher-config` | HIGH | Weak ciphers in SSL context |
| `max-version-tlsv12` | MEDIUM | Caps at TLS 1.2 |
| `no-default-ciphers` | MEDIUM | Custom cipher configuration (review needed) |
| `min-version-tlsv13` | INFO | Forces TLS 1.3 |
| `pqc-ml-kem` | INFO | Post-Quantum Cryptography adoption |

### Node.js/TypeScript (9 patterns)

| ID | Severity | Description |
|----|----------|-------------|
| `reject-unauthorized-false` | CRITICAL | `rejectUnauthorized: false` |
| `node-tls-reject-unauthorized` | CRITICAL | `NODE_TLS_REJECT_UNAUTHORIZED` env var |
| `tlsv1-method` | HIGH | Uses `TLSv1_method` |
| `tlsv11-method` | HIGH | Uses `TLSv1_1_method` |
| `min-version-weak` | HIGH | `minVersion` allows TLS 1.0/1.1 |
| `weak-cipher-config` | HIGH | Weak ciphers in TLS options |
| `max-version-tlsv12` | MEDIUM | Caps at TLS 1.2 |
| `honor-cipher-order-false` | MEDIUM | Server doesn't enforce cipher preference |
| `min-version-tlsv13` | INFO | Forces TLS 1.3 |

### C++ (10 patterns)

| ID | Severity | Description |
|----|----------|-------------|
| `ssl-ctx-verify-none` | CRITICAL | `SSL_CTX_set_verify` with `SSL_VERIFY_NONE` |
| `ssl-set-verify-none` | CRITICAL | `SSL_set_verify` with `SSL_VERIFY_NONE` |
| `tls1-version` | HIGH | Uses `TLS1_VERSION` (TLS 1.0) |
| `tls11-version` | HIGH | Uses `TLS1_1_VERSION` |
| `sslv3-method` | HIGH | Uses `SSLv3_method` |
| `tlsv1-method` | HIGH | Uses `TLSv1_method` |
| `weak-cipher-list` | HIGH | Weak ciphers via `SSL_CTX_set_cipher_list` |
| `weak-ciphersuites` | HIGH | Weak ciphers via `SSL_CTX_set_ciphersuites` |
| `max-proto-tls12` | MEDIUM | Caps at TLS 1.2 |
| `min-proto-tls13` | INFO | Forces TLS 1.3 |

### Java (11 patterns)

| ID | Severity | Description |
|----|----------|-------------|
| `allow-all-hostname-verifier` | CRITICAL | `ALLOW_ALL` HostnameVerifier |
| `trust-all-certs` | CRITICAL | Permissive TrustManager |
| `custom-ssl-socket-factory` | CRITICAL | Custom `SSLSocketFactory` bypass |
| `unversioned-ssl-context` | HIGH | `SSLContext.getInstance("TLS")` defaults to old version |
| `sslcontext-tlsv1` | HIGH | `SSLContext.getInstance("TLSv1")` |
| `sslcontext-tlsv11` | HIGH | `SSLContext.getInstance("TLSv1.1")` |
| `weak-cipher-suite` | HIGH | Weak JSSE cipher suites |
| `enabled-weak-protocols` | MEDIUM | Enables deprecated TLS protocols |
| `ssl-socket-factory-default` | MEDIUM | Default `SSLSocketFactory` may use weak ciphers |
| `sslcontext-tlsv13` | INFO | Forces TLS 1.3 only |
| `pqc-ml-kem` | INFO | Post-Quantum Cryptography adoption |

## Built-in Exclusions

The following directories are excluded from scanning by default:

- `vendor`, `.git`, `testdata`, `mocks`, `test`, `tests`, `e2e`, `testing`, `mock`, `fakes`, `fixtures`
- Go: `*_test.go` files
- Python: `*_test.py`, `test_*.py`, `conftest.py`, `__pycache__/`, `venv/`, `.venv/`
- Node.js: `*.test.js`, `*.spec.js` (and `.ts`/`.mjs`/`.mts` variants), `node_modules/`, `__tests__/`
- C++: `*_test.cpp`, `*_test.cc`

## Go-Specific: TLSSecurityProfile Noise Reduction

For Go projects, findings for `hardcoded-tls-config` (detecting `tls.Config{}`) are automatically filtered out in files that also reference `TLSSecurityProfile`, since those files are consuming centralized configuration rather than hardcoding TLS settings.

## License

Apache License 2.0 - see [LICENSE](LICENSE) for details.
