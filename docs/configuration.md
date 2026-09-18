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

### Custom Patterns

Use `extra-patterns` to add organization-specific rules without changing the action. This is a
narrow YAML list-of-maps schema; every entry requires `id`, `severity`, `name`, `description`, and
`regex`. `languages` is optional: when omitted, the pattern runs for every selected language.

```yaml
extra-patterns:
  - id: org-weak-cipher
    severity: high
    name: Organization banned cipher suite
    description: Uses a cipher suite banned by organization policy
    regex: 'TLS_RSA_WITH_AES_128_CBC_SHA'
    languages: [go, java]
```

IDs must contain only letters, numbers, `.`, `_`, and `-`, and must be unique. Supported severities
are `critical`, `high`, `medium`, and `info`; supported language scopes are `go`, `python`,
`nodejs`, `cpp`, `java`, and `rust`. Regexes are line-oriented extended regular expressions and
must not contain the scanner's pipe delimiter. Custom findings use normal exclusions, exceptions,
severity overrides, inline suppression, reports, annotations, SARIF, and threshold behavior.
Invalid custom-pattern configuration returns exit code 2 before scanning.

### Per-File/Directory Exceptions

Use `exceptions` to suppress specific patterns for specific files or directories. Each entry is `pattern-id:path`. Paths ending with `/` match as directory prefixes; other paths match exactly.

```yaml
exceptions:
  - insecure-skip-verify:test_helpers.go
  - insecure-skip-verify:tests/
  - min-version-tls10:internal/legacy/
```

Unlike `exclude-patterns` (which suppresses a pattern globally), exceptions only apply to the specified files or directories. The pattern still runs everywhere else.

### Per-Pattern Severity Overrides

Use `severity-overrides` to change the severity of individual patterns without modifying the built-in definitions. Each entry is `pattern-id:severity` where severity is one of `critical`, `high`, `medium`, or `info`.

```yaml
severity-overrides:
  - hardcoded-tls-config:high
  - prefer-server-cipher-suites:info
```

This is useful for org-specific policies where the default severity doesn't match your team's risk tolerance. The override applies everywhere the pattern matches — use `exceptions` if you need file-scoped control instead.

### Inline Suppression Comments

Add `tls-lint:ignore` in a trailing comment on any line to suppress the finding at the source:

```go
InsecureSkipVerify: true, // tls-lint:ignore
```

```python
response = requests.get(url, verify=False)  # tls-lint:ignore
```

To suppress only a specific pattern, add the pattern ID:

```go
MinVersion: tls.VersionTLS10, // tls-lint:ignore:min-version-tls10
```

A bare `tls-lint:ignore` suppresses all patterns on that line. A targeted `tls-lint:ignore:pattern-id` suppresses only the named pattern, so other patterns matching the same line are still reported.

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

### CSV or JSON Report

```yaml
- uses: sebrandon1/tls-config-lint@v1
  with:
    report-output: tls-findings.json   # or tls-findings.csv
    fail-on-findings: false
```

The format is inferred from the file extension: `.json` produces a structured JSON report with scan metadata and findings, `.csv` produces a flat CSV table. JSON requires `jq`.

### Baseline Comparison

Set `baseline` to a previous SARIF 2.1.0 file to report only new findings. A finding is
considered existing when its rule ID and normalized file path match and its line is within three
lines of a baseline result. Duplicate baseline results do not change the outcome.

```yaml
- uses: sebrandon1/tls-config-lint@v1
  with:
    baseline: artifacts/tls-baseline.sarif
    fail-on-findings: true
```

The baseline must be readable and contain SARIF results with rule IDs, artifact URIs, and start
lines. Invalid or missing baselines return exit code 2. Baseline filtering happens before
annotations, summaries, SARIF/report output, and threshold evaluation, so fully suppressed scans
produce zero findings everywhere.

### Specific Languages Only

```yaml
- uses: sebrandon1/tls-config-lint@v1
  with:
    languages: go,python
```

### Incremental Git-Diff Scans

Use incremental mode to scan only tracked files changed between two Git refs. Deleted files,
test files, and excluded directories are omitted. The scan path must be inside a Git worktree.

```yaml
- uses: sebrandon1/tls-config-lint@v1
  with:
    changed-files-only: true
    base-ref: origin/main
    head-ref: HEAD
```

The same settings can be supplied in `.tls-config-lint.yml`. Invalid refs or a non-Git scan path
return exit code 2. With no eligible changed files, the action succeeds with zero findings.

### Exclude Directories and Patterns

```yaml
- uses: sebrandon1/tls-config-lint@v1
  with:
    exclude-dirs: test/fixtures,examples/insecure
    exclude-patterns: insecure-skip-verify,hardcoded-tls-config
```

### Debug Mode

Enable debug mode to see which regex matched for each finding, useful for diagnosing false positives:

```yaml
- uses: sebrandon1/tls-config-lint@v1
  with:
    debug: true
    fail-on-findings: false
```

Each annotation will include the matched source text and the regex pattern. Debug log lines also show per-finding detail during scanning. For local CLI usage, set `DEBUG=1`:

```bash
DEBUG=1 bash entrypoint.sh
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
