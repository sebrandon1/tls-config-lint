# Configuration

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

See [`.tls-config-lint.example.yml`](../.tls-config-lint.example.yml) for a full example.

## Advanced Usage Examples

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

### Specific Languages Only

```yaml
- uses: sebrandon1/tls-config-lint@v1
  with:
    languages: go,python
```

### Exclude Directories and Patterns

```yaml
- uses: sebrandon1/tls-config-lint@v1
  with:
    exclude-dirs: test/fixtures,examples/insecure
    exclude-patterns: insecure-skip-verify,hardcoded-tls-config
```

### Custom Severity Threshold

```yaml
- uses: sebrandon1/tls-config-lint@v1
  with:
    severity-threshold: critical
```

## Exit Codes

| Code | Meaning |
|------|---------|
| `0`  | No findings at or above severity threshold |
| `1`  | Findings detected at or above threshold (`fail-on-findings: true`) |
| `2`  | Configuration or validation error (invalid inputs, missing `jq`) |
