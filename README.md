# tls-config-lint

A GitHub Action that scans your codebase for TLS configuration anti-patterns and security issues across Go, Python, Node.js/TypeScript, C++, Java, and Rust projects.

> **See also:** [tls-compliance-operator](https://github.com/sebrandon1/tls-compliance-operator) — a Kubernetes operator that continuously monitors live TLS endpoints at runtime. Use **tls-config-lint** to catch issues in source code (shift-left) and **tls-compliance-operator** to verify runtime compliance in your cluster.

## Key Features

- **82 TLS Anti-Patterns** — Across 6 languages with severity classification (critical, high, medium, info)
- **Inline PR Annotations** — Findings appear directly on affected lines in pull requests
- **SARIF Output** — Optional GitHub Code Scanning integration
- **Auto-Detection** — Discovers project languages from file markers (go.mod, package.json, etc.)
- **Configurable Thresholds** — Fail CI only on findings at or above your chosen severity
- **Per-Pattern Suppression** — Exclude specific pattern IDs from results
- **Job Summary** — Markdown findings table in the GitHub Actions summary
- **Composite Action** — No Docker build overhead

## Quick Start

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

## Outputs

| Output | Description |
|--------|-------------|
| `findings-count` | Total number of findings |
| `critical-count` | Number of critical findings |
| `high-count` | Number of high findings |
| `medium-count` | Number of medium findings |
| `info-count` | Number of info findings |
| `sarif-file` | Path to SARIF file (if generated) |

## Guides

| Guide | Description |
|-------|-------------|
| [Detected Patterns](docs/patterns.md) | All 82 patterns across 6 languages |
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
