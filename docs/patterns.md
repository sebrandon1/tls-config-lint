# Detected Patterns

tls-config-lint detects 84 TLS anti-patterns across 6 languages. Severity levels:

- **CRITICAL** — Certificate verification disabled, NULL ciphers
- **HIGH** — Weak TLS versions (1.0/1.1), broken ciphers
- **MEDIUM** — Prevents TLS 1.3 adoption
- **INFO** — Post-quantum cryptography, deprecated features

## Go (17 patterns)

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
| `grpc-insecure` | CRITICAL | gRPC connection without TLS (plaintext) |

## Python (15 patterns)

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
| `urllib3-disable-warnings` | HIGH | Hides TLS verification warnings |
| `urllib3-default-ciphers` | HIGH | Overrides global urllib3 cipher config |
| `aiohttp-ssl-false` | CRITICAL | Disables verification in aiohttp |
| `pqc-ml-kem` | INFO | Post-Quantum Cryptography adoption |
| `grpc-insecure-channel` | CRITICAL | gRPC insecure channel (plaintext) |

## Node.js/TypeScript (12 patterns)

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
| `axios-defaults-httpsagent` | MEDIUM | Global default HTTPS agent override |
| `strict-ssl-false` | CRITICAL | `strictSSL: false` disables verification |
| `secure-protocol-weak` | HIGH | Weak TLS protocol in HTTPS options |
| `min-version-tlsv13` | INFO | Forces TLS 1.3 |

## C++ (10 patterns)

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

## Java (16 patterns)

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
| `noop-hostname-verifier` | CRITICAL | Apache HttpClient `NoopHostnameVerifier` |
| `trust-all-strategy` | CRITICAL | Apache HttpClient `TrustAllStrategy` / `TrustSelfSignedStrategy` |
| `okhttp-ssl-socket-factory` | CRITICAL | OkHttp custom SSL socket factory |
| `apache-httpclient-custom-ssl` | HIGH | Custom SSLContext in Apache HttpClient |
| `ssl-connection-socket-factory` | HIGH | Custom SSL connection socket factory |
| `pqc-ml-kem` | INFO | Post-Quantum Cryptography adoption |

## Rust (14 patterns)

| ID | Severity | Description |
|----|----------|-------------|
| `danger-accept-invalid-certs` | CRITICAL | `danger_accept_invalid_certs(true)` disables certificate verification |
| `danger-accept-invalid-hostnames` | CRITICAL | `danger_accept_invalid_hostnames(true)` disables hostname verification |
| `openssl-verify-none` | CRITICAL | `SslVerifyMode::NONE` disables verification |
| `rustls-dangerous-verifier` | CRITICAL | Custom `ServerCertVerifier` bypasses verification |
| `openssl-no-hostname-verify` | CRITICAL | `set_verify_hostname(false)` disables hostname verification |
| `native-tls-proto-tlsv10` | HIGH | Uses `Protocol::Tlsv10` (TLS 1.0) |
| `native-tls-proto-tlsv11` | HIGH | Uses `Protocol::Tlsv11` (TLS 1.1) |
| `openssl-ssl3` | HIGH | Uses `SslVersion::SSL3` |
| `openssl-weak-cipher` | HIGH | Weak ciphers in cipher list |
| `min-tls-version-weak` | HIGH | Weak minimum TLS version |
| `max-version-tls12` | MEDIUM | Caps at TLS 1.2 (prevents 1.3) |
| `custom-cipher-list` | MEDIUM | Custom cipher configuration |
| `min-version-tls13` | INFO | Forces TLS 1.3 only |
| `pqc-ml-kem` | INFO | Post-Quantum Cryptography adoption |
