# Built-in Exclusions

## Default Excluded Directories

The following directories are excluded from scanning by default:

`vendor`, `.git`, `testdata`, `mocks`, `test`, `tests`, `e2e`, `testing`, `mock`, `fakes`, `fixtures`

## User-Configured Exclude Directories

`exclude-dirs` (action input or config file) adds directories to the defaults. An entry is either:

- a directory **name**, matched at any depth (`fixtures` skips every directory named `fixtures`)
- a **path relative to `scan-path`**, matched as a prefix (`internal/legacy` skips that directory
  and everything under it, but not `other/legacy`)

Both forms apply to full and incremental scans.

## Language-Specific Test File Exclusions

- **Go:** `*_test.go` files
- **Python:** `*_test.py`, `test_*.py`, `conftest.py`, `__pycache__/`, `venv/`, `.venv/`
- **Node.js:** `*.test.js`, `*.spec.js` (and `.ts`/`.mjs`/`.mts` variants), `node_modules/`, `__tests__/`
- **C++:** `*_test.cpp`, `*_test.cc`
- **Java:** `*Test.java`, `*Tests.java`, `*IT.java`, `target/`, `build/`, `.gradle/`
- **Kotlin:** `*_test.kt`
- **C#/.NET:** `*_test.cs`
- **PHP:** `*_test.php`, `test_*.php`
- **Ruby:** `*_test.rb`, `test_*.rb`
- **Rust:** `*_test.rs`, `*_tests.rs`, `target/`, `.cargo/`

## Go TLSSecurityProfile Noise Reduction

For Go projects, findings for `hardcoded-tls-config` (detecting `tls.Config{}`) are automatically filtered out in files that also reference `TLSSecurityProfile`, since those files are consuming centralized configuration rather than hardcoding TLS settings.
