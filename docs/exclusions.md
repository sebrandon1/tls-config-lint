# Built-in Exclusions

## Default Excluded Directories

The following directories are excluded from scanning by default:

`vendor`, `.git`, `testdata`, `mocks`, `test`, `tests`, `e2e`, `testing`, `mock`, `fakes`, `fixtures`

## Language-Specific Test File Exclusions

- **Go:** `*_test.go` files
- **Python:** `*_test.py`, `test_*.py`, `conftest.py`, `__pycache__/`, `venv/`, `.venv/`
- **Node.js:** `*.test.js`, `*.spec.js` (and `.ts`/`.mjs`/`.mts` variants), `node_modules/`, `__tests__/`
- **C++:** `*_test.cpp`, `*_test.cc`
- **Java:** `*Test.java`, `*Tests.java`, `*IT.java`, `target/`, `build/`, `.gradle/`
- **Rust:** `*_test.rs`, `*_tests.rs`, `target/`, `.cargo/`

## Go TLSSecurityProfile Noise Reduction

For Go projects, findings for `hardcoded-tls-config` (detecting `tls.Config{}`) are automatically filtered out in files that also reference `TLSSecurityProfile`, since those files are consuming centralized configuration rather than hardcoding TLS settings.
