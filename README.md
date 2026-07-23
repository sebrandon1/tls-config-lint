# tls-config-lint

A GitHub Action that scans your codebase for TLS configuration anti-patterns and security issues across Go, Python, Node.js/TypeScript, C++, Java, and Rust projects.

> **See also:** [tls-compliance-operator](https://github.com/sebrandon1/tls-compliance-operator) — a Kubernetes operator that continuously monitors live TLS endpoints at runtime. Use **tls-config-lint** to catch issues in source code (shift-left) and **tls-compliance-operator** to verify runtime compliance in your cluster.
>
> **See also:** [openshift/tls-scanner](https://github.com/openshift/tls-scanner) — a batch Job-based TLS auditing tool from the OpenShift team for one-shot cluster scans.

## Key Features

- **86 TLS Anti-Patterns** — Across 6 languages with severity classification (critical, high, medium, info)
- **Inline PR Annotations** — Findings appear directly on affected lines in pull requests
- **SARIF Output** — Optional GitHub Code Scanning integration
- **Auto-Detection** — Discovers project languages from file markers (go.mod, package.json, etc.)
- **Configurable Thresholds** — Fail CI only on findings at or above your chosen severity
- **Per-Pattern Suppression** — Exclude specific pattern IDs from results
- **Job Summary** — Markdown findings table in the GitHub Actions summary
- **Composite Action** — No Docker build overhead

## Getting Started

### 1. Add the workflow

Create `.github/workflows/tls-lint.yml` in your repository:

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

That's it — push the file and the action auto-detects your project languages and scans for TLS anti-patterns.

### 2. Understand the output

When findings are detected, they appear in three places:

- **PR annotations** — Inline comments on the affected lines in your pull request
- **Job summary** — A severity table and findings list in the Actions run summary
- **Exit code** — The step fails (exit 1) if findings meet or exceed the severity threshold

Each finding includes a link to its [remediation docs](docs/patterns.md) with insecure/secure code examples.

### 3. Interpret severity levels

| Level | Meaning | Examples |
|-------|---------|----------|
| **CRITICAL** | Verification disabled, NULL ciphers | `InsecureSkipVerify: true`, `verify=False` |
| **HIGH** | Weak TLS versions, broken ciphers | TLS 1.0/1.1, RC4, 3DES |
| **MEDIUM** | Prevents TLS 1.3 adoption | `MaxVersion: TLS 1.2` |
| **INFO** | Post-quantum, deprecated features | PQC/ML-KEM, `PreferServerCipherSuites` |

By default, the action fails on HIGH and above. Change the threshold:

```yaml
- uses: sebrandon1/tls-config-lint@v1
  with:
    severity-threshold: critical  # only fail on critical findings
```

### 4. Suppress false positives

**Inline** — Add a comment on the affected line:

```go
InsecureSkipVerify: true, // tls-lint:ignore
```

**By pattern** — Exclude specific pattern IDs:

```yaml
- uses: sebrandon1/tls-config-lint@v1
  with:
    exclude-patterns: insecure-skip-verify,hardcoded-tls-config
```

**By file** — Create a `.tls-config-lint.yml` config file:

```yaml
exceptions:
  - insecure-skip-verify:test_helpers.go
  - min-version-tls10:internal/legacy/
```

See [Configuration](docs/configuration.md) for all options including severity overrides, report output, and debug mode.

### 5. Enable GitHub Code Scanning (optional)

Add SARIF output for findings in the Security tab:

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

## Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `severity-threshold` | `high` | Minimum severity to cause failure: `critical`, `high`, `medium`, `info` |
| `languages` | `auto` | Comma-separated: `go,python,nodejs,cpp,java,rust` or `auto` to detect |
| `exclude-dirs` | _(empty)_ | Additional dirs to exclude (comma-separated) |
| `exclude-patterns` | _(empty)_ | Pattern IDs to suppress (comma-separated) |
| `config-file` | `.tls-config-lint.yml` | Path to optional repo config file |
| `scan-path` | `.` | Directory to scan |
| `fail-on-findings` | `true` | Whether to fail CI on findings above threshold |
| `sarif-output` | _(empty)_ | Path to write SARIF file (empty = disabled) |
| `report-output` | _(empty)_ | Path to write CSV or JSON report (format inferred from extension) |
| `debug` | `false` | Show which regex matched for each finding |

## Outputs

| Output | Description |
|--------|-------------|
| `findings-count` | Total number of findings |
| `critical-count` | Number of critical findings |
| `high-count` | Number of high findings |
| `medium-count` | Number of medium findings |
| `info-count` | Number of info findings |
| `sarif-file` | Path to SARIF file (if generated) |
| `report-file` | Path to report file (if generated) |
| `scan-duration` | Scan duration (e.g. `3s`) |

## Guides

| Guide | Description |
|-------|-------------|
| [Detected Patterns](docs/patterns.md) | All 86 patterns across 6 languages |
| [Configuration](docs/configuration.md) | Config file, advanced usage examples, exit codes |
| [Built-in Exclusions](docs/exclusions.md) | Default excluded directories and test files |

## Development

```bash
bash tests/run_tests.sh          # Run all unit tests
shfmt -d -i 0 -ci .              # Check formatting
shellcheck -S warning entrypoint.sh lib/*.sh patterns/*.sh tests/*.sh  # Static analysis
```

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

Apache License 2.0 - see [LICENSE](LICENSE) for details.
