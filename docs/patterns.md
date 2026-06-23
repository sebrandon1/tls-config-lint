# Detected Patterns

tls-config-lint detects 86 TLS anti-patterns across 6 languages. Severity levels:

- **CRITICAL** — Certificate verification disabled, NULL ciphers
- **HIGH** — Weak TLS versions (1.0/1.1), broken ciphers
- **MEDIUM** — Prevents TLS 1.3 adoption
- **INFO** — Post-quantum cryptography, deprecated features

## Go (17 patterns)

| ID | Severity | Description |
|----|----------|-------------|
| [`insecure-skip-verify`](#go-insecure-skip-verify) | CRITICAL | `InsecureSkipVerify: true` disables certificate verification |
| [`weak-cipher-rc4`](#go-weak-cipher-rc4) | CRITICAL | RC4 cipher suite (completely broken) |
| [`null-cipher`](#go-null-cipher) | CRITICAL | NULL cipher suite (no encryption) |
| [`grpc-insecure`](#go-grpc-insecure) | CRITICAL | gRPC connection without TLS (plaintext) |
| [`min-version-tls10`](#go-min-version-tls10) | HIGH | `MinVersion` set to TLS 1.0 |
| [`min-version-tls11`](#go-min-version-tls11) | HIGH | `MinVersion` set to TLS 1.1 |
| [`max-version-tls10`](#go-max-version-tls10) | HIGH | `MaxVersion` set to TLS 1.0 |
| [`max-version-tls11`](#go-max-version-tls11) | HIGH | `MaxVersion` set to TLS 1.1 |
| [`weak-cipher-3des`](#go-weak-cipher-3des) | HIGH | 3DES/CBC cipher suites |
| [`tls-profile-old`](#go-tls-profile-old) | HIGH | Old TLS security profile allows TLS 1.0/1.1 |
| [`max-version-tls12`](#go-max-version-tls12) | MEDIUM | `MaxVersion` set to TLS 1.2 (prevents 1.3) |
| [`tls-profile-custom`](#go-tls-profile-custom) | MEDIUM | Custom TLS security profile needs review |
| [`min-version-tls13`](#go-min-version-tls13) | INFO | Forces TLS 1.3 only |
| [`prefer-server-cipher-suites`](#go-prefer-server-cipher-suites) | INFO | Deprecated in Go 1.17+ |
| [`curve-preferences`](#go-curve-preferences) | INFO | Explicit curve configuration |
| [`hardcoded-tls-config`](#go-hardcoded-tls-config) | INFO | Hardcoded `tls.Config{}` |
| [`pqc-ml-kem`](#go-pqc-ml-kem) | INFO | Post-Quantum Cryptography adoption |

## Python (15 patterns)

| ID | Severity | Description |
|----|----------|-------------|
| [`verify-false`](#python-verify-false) | CRITICAL | `verify=False` disables certificate verification |
| [`cert-none`](#python-cert-none) | CRITICAL | `ssl.CERT_NONE` disables verification |
| [`create-unverified-context`](#python-create-unverified-context) | CRITICAL | `_create_unverified_context()` |
| [`check-hostname-false`](#python-check-hostname-false) | CRITICAL | `check_hostname = False` |
| [`aiohttp-ssl-false`](#python-aiohttp-ssl-false) | CRITICAL | Disables verification in aiohttp |
| [`grpc-insecure-channel`](#python-grpc-insecure-channel) | CRITICAL | gRPC insecure channel (plaintext) |
| [`protocol-tlsv1`](#python-protocol-tlsv1) | HIGH | Uses `PROTOCOL_TLSv1` (TLS 1.0) |
| [`protocol-tlsv11`](#python-protocol-tlsv11) | HIGH | Uses `PROTOCOL_TLSv1_1` |
| [`weak-cipher-config`](#python-weak-cipher-config) | HIGH | Weak ciphers in SSL context |
| [`urllib3-disable-warnings`](#python-urllib3-disable-warnings) | HIGH | Hides TLS verification warnings |
| [`urllib3-default-ciphers`](#python-urllib3-default-ciphers) | HIGH | Overrides global urllib3 cipher config |
| [`max-version-tlsv12`](#python-max-version-tlsv12) | MEDIUM | Caps at TLS 1.2 |
| [`no-default-ciphers`](#python-no-default-ciphers) | MEDIUM | Custom cipher configuration (review needed) |
| [`min-version-tlsv13`](#python-min-version-tlsv13) | INFO | Forces TLS 1.3 |
| [`pqc-ml-kem`](#python-pqc-ml-kem) | INFO | Post-Quantum Cryptography adoption |

## Node.js/TypeScript (12 patterns)

| ID | Severity | Description |
|----|----------|-------------|
| [`reject-unauthorized-false`](#nodejs-reject-unauthorized-false) | CRITICAL | `rejectUnauthorized: false` |
| [`node-tls-reject-unauthorized`](#nodejs-node-tls-reject-unauthorized) | CRITICAL | `NODE_TLS_REJECT_UNAUTHORIZED` env var |
| [`strict-ssl-false`](#nodejs-strict-ssl-false) | CRITICAL | `strictSSL: false` disables verification |
| [`tlsv1-method`](#nodejs-tlsv1-method) | HIGH | Uses `TLSv1_method` |
| [`tlsv11-method`](#nodejs-tlsv11-method) | HIGH | Uses `TLSv1_1_method` |
| [`min-version-weak`](#nodejs-min-version-weak) | HIGH | `minVersion` allows TLS 1.0/1.1 |
| [`weak-cipher-config`](#nodejs-weak-cipher-config) | HIGH | Weak ciphers in TLS options |
| [`secure-protocol-weak`](#nodejs-secure-protocol-weak) | HIGH | Weak TLS protocol in HTTPS options |
| [`max-version-tlsv12`](#nodejs-max-version-tlsv12) | MEDIUM | Caps at TLS 1.2 |
| [`honor-cipher-order-false`](#nodejs-honor-cipher-order-false) | MEDIUM | Server doesn't enforce cipher preference |
| [`axios-defaults-httpsagent`](#nodejs-axios-defaults-httpsagent) | MEDIUM | Global default HTTPS agent override |
| [`min-version-tlsv13`](#nodejs-min-version-tlsv13) | INFO | Forces TLS 1.3 |

## C++ (12 patterns)

| ID | Severity | Description |
|----|----------|-------------|
| [`ssl-ctx-verify-none`](#cpp-ssl-ctx-verify-none) | CRITICAL | `SSL_CTX_set_verify` with `SSL_VERIFY_NONE` |
| [`ssl-set-verify-none`](#cpp-ssl-set-verify-none) | CRITICAL | `SSL_set_verify` with `SSL_VERIFY_NONE` |
| [`curl-ssl-verifypeer-off`](#cpp-curl-ssl-verifypeer-off) | CRITICAL | `CURLOPT_SSL_VERIFYPEER` disabled (libcurl) |
| [`curl-ssl-verifyhost-off`](#cpp-curl-ssl-verifyhost-off) | CRITICAL | `CURLOPT_SSL_VERIFYHOST` disabled (libcurl) |
| [`tls1-version`](#cpp-tls1-version) | HIGH | Uses `TLS1_VERSION` (TLS 1.0) |
| [`tls11-version`](#cpp-tls11-version) | HIGH | Uses `TLS1_1_VERSION` |
| [`sslv3-method`](#cpp-sslv3-method) | HIGH | Uses `SSLv3_method` |
| [`tlsv1-method`](#cpp-tlsv1-method) | HIGH | Uses `TLSv1_method` |
| [`weak-cipher-list`](#cpp-weak-cipher-list) | HIGH | Weak ciphers via `SSL_CTX_set_cipher_list` |
| [`weak-ciphersuites`](#cpp-weak-ciphersuites) | HIGH | Weak ciphers via `SSL_CTX_set_ciphersuites` |
| [`max-proto-tls12`](#cpp-max-proto-tls12) | MEDIUM | Caps at TLS 1.2 |
| [`min-proto-tls13`](#cpp-min-proto-tls13) | INFO | Forces TLS 1.3 |

## Java (16 patterns)

| ID | Severity | Description |
|----|----------|-------------|
| [`allow-all-hostname-verifier`](#java-allow-all-hostname-verifier) | CRITICAL | `ALLOW_ALL` HostnameVerifier |
| [`trust-all-certs`](#java-trust-all-certs) | CRITICAL | Permissive TrustManager |
| [`custom-ssl-socket-factory`](#java-custom-ssl-socket-factory) | CRITICAL | Custom `SSLSocketFactory` bypass |
| [`noop-hostname-verifier`](#java-noop-hostname-verifier) | CRITICAL | Apache HttpClient `NoopHostnameVerifier` |
| [`trust-all-strategy`](#java-trust-all-strategy) | CRITICAL | Apache HttpClient `TrustAllStrategy` / `TrustSelfSignedStrategy` |
| [`okhttp-ssl-socket-factory`](#java-okhttp-ssl-socket-factory) | CRITICAL | OkHttp custom SSL socket factory |
| [`unversioned-ssl-context`](#java-unversioned-ssl-context) | HIGH | `SSLContext.getInstance("TLS")` defaults to old version |
| [`sslcontext-tlsv1`](#java-sslcontext-tlsv1) | HIGH | `SSLContext.getInstance("TLSv1")` |
| [`sslcontext-tlsv11`](#java-sslcontext-tlsv11) | HIGH | `SSLContext.getInstance("TLSv1.1")` |
| [`weak-cipher-suite`](#java-weak-cipher-suite) | HIGH | Weak JSSE cipher suites |
| [`apache-httpclient-custom-ssl`](#java-apache-httpclient-custom-ssl) | HIGH | Custom SSLContext in Apache HttpClient |
| [`ssl-connection-socket-factory`](#java-ssl-connection-socket-factory) | HIGH | Custom SSL connection socket factory |
| [`enabled-weak-protocols`](#java-enabled-weak-protocols) | MEDIUM | Enables deprecated TLS protocols |
| [`ssl-socket-factory-default`](#java-ssl-socket-factory-default) | MEDIUM | Default `SSLSocketFactory` may use weak ciphers |
| [`sslcontext-tlsv13`](#java-sslcontext-tlsv13) | INFO | Forces TLS 1.3 only |
| [`pqc-ml-kem`](#java-pqc-ml-kem) | INFO | Post-Quantum Cryptography adoption |

## Rust (14 patterns)

| ID | Severity | Description |
|----|----------|-------------|
| [`danger-accept-invalid-certs`](#rust-danger-accept-invalid-certs) | CRITICAL | `danger_accept_invalid_certs(true)` disables certificate verification |
| [`danger-accept-invalid-hostnames`](#rust-danger-accept-invalid-hostnames) | CRITICAL | `danger_accept_invalid_hostnames(true)` disables hostname verification |
| [`openssl-verify-none`](#rust-openssl-verify-none) | CRITICAL | `SslVerifyMode::NONE` disables verification |
| [`rustls-dangerous-verifier`](#rust-rustls-dangerous-verifier) | CRITICAL | Custom `ServerCertVerifier` bypasses verification |
| [`openssl-no-hostname-verify`](#rust-openssl-no-hostname-verify) | CRITICAL | `set_verify_hostname(false)` disables hostname verification |
| [`native-tls-proto-tlsv10`](#rust-native-tls-proto-tlsv10) | HIGH | Uses `Protocol::Tlsv10` (TLS 1.0) |
| [`native-tls-proto-tlsv11`](#rust-native-tls-proto-tlsv11) | HIGH | Uses `Protocol::Tlsv11` (TLS 1.1) |
| [`openssl-ssl3`](#rust-openssl-ssl3) | HIGH | Uses `SslVersion::SSL3` |
| [`openssl-weak-cipher`](#rust-openssl-weak-cipher) | HIGH | Weak ciphers in cipher list |
| [`min-tls-version-weak`](#rust-min-tls-version-weak) | HIGH | Weak minimum TLS version |
| [`max-version-tls12`](#rust-max-version-tls12) | MEDIUM | Caps at TLS 1.2 (prevents 1.3) |
| [`custom-cipher-list`](#rust-custom-cipher-list) | MEDIUM | Custom cipher configuration |
| [`min-version-tls13`](#rust-min-version-tls13) | INFO | Forces TLS 1.3 only |
| [`pqc-ml-kem`](#rust-pqc-ml-kem) | INFO | Post-Quantum Cryptography adoption |

---

## Remediation Reference

Each pattern below includes a brief explanation of the security risk, an insecure code example that triggers the finding, and a secure alternative.

## Go

<a id="go-insecure-skip-verify"></a>

### InsecureSkipVerify: true

**ID:** `insecure-skip-verify` | **Severity:** CRITICAL

Disables TLS certificate verification entirely, allowing any certificate including self-signed and expired ones. This enables man-in-the-middle attacks where an attacker can intercept and modify all traffic.

**Insecure:**
```go
tlsConfig := &tls.Config{
    InsecureSkipVerify: true,
}
```

**Secure:**
```go
tlsConfig := &tls.Config{
    MinVersion: tls.VersionTLS12,
}
```

<a id="go-weak-cipher-rc4"></a>

### RC4 cipher suite

**ID:** `weak-cipher-rc4` | **Severity:** CRITICAL

RC4 is a completely broken stream cipher with multiple practical attacks. RFC 7465 prohibits its use in TLS. Any data encrypted with RC4 should be considered compromised.

**Insecure:**
```go
tlsConfig := &tls.Config{
    CipherSuites: []uint16{
        tls.TLS_RSA_WITH_RC4_128_SHA,
    },
}
```

**Secure:**
```go
tlsConfig := &tls.Config{
    MinVersion: tls.VersionTLS12,
    // Let Go select secure cipher suites automatically
}
```

<a id="go-null-cipher"></a>

### NULL cipher suite

**ID:** `null-cipher` | **Severity:** CRITICAL

NULL ciphers provide authentication but no encryption whatsoever. All data is transmitted in plaintext over the wire, defeating the purpose of TLS entirely.

**Insecure:**
```go
tlsConfig := &tls.Config{
    CipherSuites: []uint16{
        tls.TLS_RSA_WITH_NULL_SHA,
    },
}
```

**Secure:**
```go
tlsConfig := &tls.Config{
    MinVersion: tls.VersionTLS12,
    // Let Go select secure cipher suites automatically
}
```

<a id="go-grpc-insecure"></a>

### gRPC insecure connection

**ID:** `grpc-insecure` | **Severity:** CRITICAL

Establishes a gRPC connection without TLS, transmitting all data including credentials and RPC payloads in plaintext. An attacker on the network can read and modify all gRPC traffic.

**Insecure:**
```go
conn, err := grpc.Dial("server:50051",
    grpc.WithTransportCredentials(insecure.NewCredentials()),
)
```

**Secure:**
```go
creds, err := credentials.NewClientTLSFromFile("ca.pem", "")
conn, err := grpc.Dial("server:50051",
    grpc.WithTransportCredentials(creds),
)
```

<a id="go-min-version-tls10"></a>

### MinVersion TLS 1.0

**ID:** `min-version-tls10` | **Severity:** HIGH

TLS 1.0 has known vulnerabilities including POODLE and BEAST attacks. It has been deprecated by RFC 8996 and is prohibited by PCI DSS 3.2+.

**Insecure:**
```go
tlsConfig := &tls.Config{
    MinVersion: tls.VersionTLS10,
}
```

**Secure:**
```go
tlsConfig := &tls.Config{
    MinVersion: tls.VersionTLS12,
}
```

<a id="go-min-version-tls11"></a>

### MinVersion TLS 1.1

**ID:** `min-version-tls11` | **Severity:** HIGH

TLS 1.1 lacks support for modern authenticated encryption (AEAD) ciphers and has been deprecated by RFC 8996. All major browsers and cloud providers have dropped TLS 1.1 support.

**Insecure:**
```go
tlsConfig := &tls.Config{
    MinVersion: tls.VersionTLS11,
}
```

**Secure:**
```go
tlsConfig := &tls.Config{
    MinVersion: tls.VersionTLS12,
}
```

<a id="go-max-version-tls10"></a>

### MaxVersion TLS 1.0

**ID:** `max-version-tls10` | **Severity:** HIGH

Capping the maximum TLS version at 1.0 forces the use of a deprecated, vulnerable protocol and prevents negotiation of any secure version. This is almost always a misconfiguration.

**Insecure:**
```go
tlsConfig := &tls.Config{
    MaxVersion: tls.VersionTLS10,
}
```

**Secure:**
```go
tlsConfig := &tls.Config{
    MinVersion: tls.VersionTLS12,
    // Omit MaxVersion to allow the highest supported version
}
```

<a id="go-max-version-tls11"></a>

### MaxVersion TLS 1.1

**ID:** `max-version-tls11` | **Severity:** HIGH

Capping the maximum TLS version at 1.1 prevents the use of TLS 1.2 and 1.3, which provide critical security improvements including AEAD ciphers and resistance to downgrade attacks.

**Insecure:**
```go
tlsConfig := &tls.Config{
    MaxVersion: tls.VersionTLS11,
}
```

**Secure:**
```go
tlsConfig := &tls.Config{
    MinVersion: tls.VersionTLS12,
    // Omit MaxVersion to allow the highest supported version
}
```

<a id="go-weak-cipher-3des"></a>

### 3DES/CBC cipher suite

**ID:** `weak-cipher-3des` | **Severity:** HIGH

3DES has an effective key strength of only 112 bits and is vulnerable to the Sweet32 birthday attack. CBC-mode ciphers are susceptible to padding oracle attacks such as Lucky13.

**Insecure:**
```go
tlsConfig := &tls.Config{
    CipherSuites: []uint16{
        tls.TLS_RSA_WITH_3DES_EDE_CBC_SHA,
    },
}
```

**Secure:**
```go
tlsConfig := &tls.Config{
    MinVersion: tls.VersionTLS12,
    CipherSuites: []uint16{
        tls.TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,
        tls.TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,
    },
}
```

<a id="go-tls-profile-old"></a>

### Old TLS security profile

**ID:** `tls-profile-old` | **Severity:** HIGH

The OpenShift Old TLS profile enables TLS 1.0 and 1.1 along with weak cipher suites for backward compatibility. This exposes the cluster to known protocol-level attacks and should only be used temporarily during migration.

**Insecure:**
```go
tlsConfig := &configv1.TLSSecurityProfile{
    Type: configv1.TLSProfileOldType,
}
```

**Secure:**
```go
tlsConfig := &configv1.TLSSecurityProfile{
    Type: configv1.TLSProfileIntermediateType,
}
```

<a id="go-max-version-tls12"></a>

### MaxVersion TLS 1.2

**ID:** `max-version-tls12` | **Severity:** MEDIUM

Capping MaxVersion at TLS 1.2 prevents negotiation of TLS 1.3, which provides improved performance, stronger key exchange, and a simplified handshake that eliminates entire categories of past vulnerabilities.

**Insecure:**
```go
tlsConfig := &tls.Config{
    MinVersion: tls.VersionTLS12,
    MaxVersion: tls.VersionTLS12,
}
```

**Secure:**
```go
tlsConfig := &tls.Config{
    MinVersion: tls.VersionTLS12,
    // Omit MaxVersion to allow TLS 1.3 negotiation
}
```

<a id="go-tls-profile-custom"></a>

### Custom TLS security profile

**ID:** `tls-profile-custom` | **Severity:** MEDIUM

A custom OpenShift TLS profile bypasses the curated Intermediate and Modern profiles. Manual cipher and protocol selection may inadvertently allow weak configurations and requires ongoing maintenance as new vulnerabilities are discovered.

**Insecure:**
```go
tlsConfig := &configv1.TLSSecurityProfile{
    Type: configv1.TLSProfileCustomType,
    Custom: &configv1.CustomTLSProfile{...},
}
```

**Secure:**
```go
tlsConfig := &configv1.TLSSecurityProfile{
    Type: configv1.TLSProfileIntermediateType,
}
```

<a id="go-min-version-tls13"></a>

### MinVersion TLS 1.3

**ID:** `min-version-tls13` | **Severity:** INFO

> **Informational.** Setting MinVersion to TLS 1.3 ensures only the strongest protocol is used, but may break compatibility with older clients or infrastructure that only supports TLS 1.2. Flagged for awareness; no fix is required if your environment fully supports TLS 1.3.

<a id="go-prefer-server-cipher-suites"></a>

### PreferServerCipherSuites

**ID:** `prefer-server-cipher-suites` | **Severity:** INFO

> **Informational.** `PreferServerCipherSuites` was deprecated in Go 1.17 and is ignored by the runtime. Go's TLS stack now automatically prefers the server's cipher order when it provides a security benefit. This field can be safely removed.

<a id="go-curve-preferences"></a>

### CurvePreferences

**ID:** `curve-preferences` | **Severity:** INFO

> **Informational.** Explicitly setting CurvePreferences pins the elliptic curves used in key exchange. This is flagged as a post-quantum readiness indicator since adding ML-KEM curves here is how Go will adopt hybrid PQC key exchange. No fix is required.

<a id="go-hardcoded-tls-config"></a>

### Hardcoded tls.Config

**ID:** `hardcoded-tls-config` | **Severity:** INFO

> **Informational.** A hardcoded `tls.Config{}` literal may diverge from organizational TLS policy or API server profiles over time. Consider using a shared configuration helper or referencing an OpenShift TLS security profile instead. No fix is required.

<a id="go-pqc-ml-kem"></a>

### PQC/ML-KEM patterns

**ID:** `pqc-ml-kem` | **Severity:** INFO

> **Informational.** Detects usage of ML-KEM (Module Lattice Key Encapsulation Mechanism) and related post-quantum cryptography APIs. This is an adoption tracker for PQC migration readiness, not a security issue. No fix is required.

## Python

<a id="python-verify-false"></a>

### verify=False

**ID:** `verify-false` | **Severity:** CRITICAL

Passing `verify=False` to the requests library disables TLS certificate verification, making the connection vulnerable to man-in-the-middle attacks. Any attacker on the network can intercept credentials and data.

**Insecure:**
```python
response = requests.get("https://api.example.com",
    verify=False)
```

**Secure:**
```python
response = requests.get("https://api.example.com",
    verify="/path/to/ca-bundle.crt")
```

<a id="python-cert-none"></a>

### ssl.CERT_NONE

**ID:** `cert-none` | **Severity:** CRITICAL

Setting `verify_mode` to `ssl.CERT_NONE` disables all certificate validation in the ssl module. The connection will accept any certificate, including self-signed, expired, or certificates issued for a different hostname.

**Insecure:**
```python
ctx = ssl.create_default_context()
ctx.verify_mode = ssl.CERT_NONE
```

**Secure:**
```python
ctx = ssl.create_default_context()
ctx.verify_mode = ssl.CERT_REQUIRED
```

<a id="python-create-unverified-context"></a>

### _create_unverified_context

**ID:** `create-unverified-context` | **Severity:** CRITICAL

`ssl._create_unverified_context()` is a private API that creates an SSL context with all verification disabled. It exists only for backward compatibility and should never be used in production code.

**Insecure:**
```python
ctx = ssl._create_unverified_context()
urllib.request.urlopen(url, context=ctx)
```

**Secure:**
```python
ctx = ssl.create_default_context()
urllib.request.urlopen(url, context=ctx)
```

<a id="python-check-hostname-false"></a>

### check_hostname = False

**ID:** `check-hostname-false` | **Severity:** CRITICAL

Disabling hostname verification means the client will accept a valid certificate issued for any domain. An attacker with any trusted certificate can impersonate the target server.

**Insecure:**
```python
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE
```

**Secure:**
```python
ctx = ssl.create_default_context()
# check_hostname is True by default
```

<a id="python-aiohttp-ssl-false"></a>

### aiohttp ssl=False

**ID:** `aiohttp-ssl-false` | **Severity:** CRITICAL

Passing `ssl=False` to aiohttp's TCPConnector or ClientSession disables all TLS certificate verification for async HTTP requests. This is the aiohttp equivalent of `verify=False` in the requests library.

**Insecure:**
```python
connector = aiohttp.TCPConnector(ssl=False)
session = aiohttp.ClientSession(connector=connector)
```

**Secure:**
```python
ssl_ctx = ssl.create_default_context()
connector = aiohttp.TCPConnector(ssl=ssl_ctx)
session = aiohttp.ClientSession(connector=connector)
```

<a id="python-grpc-insecure-channel"></a>

### gRPC insecure channel

**ID:** `grpc-insecure-channel` | **Severity:** CRITICAL

`grpc.insecure_channel()` creates a gRPC connection without any TLS encryption. All data including authentication tokens and RPC payloads are transmitted in plaintext.

**Insecure:**
```python
channel = grpc.insecure_channel("server:50051")
stub = service_pb2_grpc.MyServiceStub(channel)
```

**Secure:**
```python
creds = grpc.ssl_channel_credentials(
    root_certificates=open("ca.pem", "rb").read())
channel = grpc.secure_channel("server:50051", creds)
```

<a id="python-protocol-tlsv1"></a>

### PROTOCOL_TLSv1 (1.0)

**ID:** `protocol-tlsv1` | **Severity:** HIGH

TLS 1.0 has known vulnerabilities including POODLE and BEAST attacks. It was deprecated by RFC 8996 in 2021. `PROTOCOL_TLSv1` is also deprecated in Python 3.10+.

**Insecure:**
```python
ctx = ssl.SSLContext(ssl.PROTOCOL_TLSv1)
```

**Secure:**
```python
ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
ctx.minimum_version = ssl.TLSVersion.TLSv1_2
```

<a id="python-protocol-tlsv11"></a>

### PROTOCOL_TLSv1_1

**ID:** `protocol-tlsv11` | **Severity:** HIGH

TLS 1.1 lacks support for AEAD ciphers and was deprecated by RFC 8996. `PROTOCOL_TLSv1_1` is deprecated in Python 3.10+ and may raise a `DeprecationWarning`.

**Insecure:**
```python
ctx = ssl.SSLContext(ssl.PROTOCOL_TLSv1_1)
```

**Secure:**
```python
ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
ctx.minimum_version = ssl.TLSVersion.TLSv1_2
```

<a id="python-weak-cipher-config"></a>

### Weak cipher configuration

**ID:** `weak-cipher-config` | **Severity:** HIGH

Configuring weak or broken ciphers such as DES, RC4, NULL, or EXPORT suites allows attackers to break encryption. These ciphers have known practical attacks that can recover plaintext data.

**Insecure:**
```python
ctx = ssl.create_default_context()
ctx.set_ciphers("DES-CBC3-SHA:RC4-SHA:NULL-SHA")
```

**Secure:**
```python
ctx = ssl.create_default_context()
# Default ciphers are already secure; only restrict further if needed
ctx.set_ciphers("ECDHE+AESGCM:ECDHE+CHACHA20:DHE+AESGCM")
```

<a id="python-urllib3-disable-warnings"></a>

### urllib3 disable_warnings

**ID:** `urllib3-disable-warnings` | **Severity:** HIGH

Calling `urllib3.disable_warnings()` suppresses InsecureRequestWarning, which is the safety net that alerts developers when `verify=False` is used. Silencing this warning hides a real security problem rather than fixing it.

**Insecure:**
```python
import urllib3
urllib3.disable_warnings()
requests.get("https://api.example.com", verify=False)
```

**Secure:**
```python
# Fix the root cause: use proper certificate verification
requests.get("https://api.example.com",
    verify="/path/to/ca-bundle.crt")
```

<a id="python-urllib3-default-ciphers"></a>

### urllib3 DEFAULT_CIPHERS override

**ID:** `urllib3-default-ciphers` | **Severity:** HIGH

Overriding `urllib3.util.ssl_.DEFAULT_CIPHERS` changes the global cipher configuration for all HTTPS connections made through urllib3 and requests. This can silently weaken TLS for the entire application.

**Insecure:**
```python
import urllib3
urllib3.util.ssl_.DEFAULT_CIPHERS = "ALL:!aNULL"
```

**Secure:**
```python
# Use per-connection SSL context instead of global override
ctx = ssl.create_default_context()
ctx.set_ciphers("ECDHE+AESGCM:ECDHE+CHACHA20")
```

<a id="python-max-version-tlsv12"></a>

### maximum_version TLSv1_2

**ID:** `max-version-tlsv12` | **Severity:** MEDIUM

Capping `maximum_version` at TLS 1.2 prevents the client from negotiating TLS 1.3, which offers improved security through mandatory forward secrecy, encrypted handshake extensions, and a simplified design that removes legacy vulnerabilities.

**Insecure:**
```python
ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
ctx.maximum_version = ssl.TLSVersion.TLSv1_2
```

**Secure:**
```python
ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
ctx.minimum_version = ssl.TLSVersion.TLSv1_2
# Omit maximum_version to allow TLS 1.3
```

<a id="python-no-default-ciphers"></a>

### Custom cipher configuration

**ID:** `no-default-ciphers` | **Severity:** MEDIUM

Calling `set_ciphers()` overrides Python's secure default cipher list. Custom cipher strings may inadvertently exclude strong ciphers or include weak ones, and require ongoing maintenance as cryptographic best practices evolve.

**Insecure:**
```python
ctx = ssl.create_default_context()
ctx.set_ciphers("AES128-SHA:AES256-SHA")
```

**Secure:**
```python
ctx = ssl.create_default_context()
# Default ciphers are curated by Python maintainers
# Only call set_ciphers() if you have a specific compliance requirement
```

<a id="python-min-version-tlsv13"></a>

### minimum_version TLSv1_3

**ID:** `min-version-tlsv13` | **Severity:** INFO

> **Informational.** Setting `minimum_version` to TLS 1.3 ensures the strongest protocol version, but may break compatibility with older servers or proxies that only support TLS 1.2. Flagged for awareness; no fix is required if your environment fully supports TLS 1.3.

<a id="python-pqc-ml-kem"></a>

### PQC/ML-KEM patterns

**ID:** `pqc-ml-kem` | **Severity:** INFO

> **Informational.** Detects usage of ML-KEM, post-quantum cryptography libraries, and related keywords. This is an adoption tracker for PQC migration readiness, not a security issue. No fix is required.

## Node.js / TypeScript

<a id="nodejs-reject-unauthorized-false"></a>

### rejectUnauthorized: false

**ID:** `reject-unauthorized-false` | **Severity:** CRITICAL

Disabling `rejectUnauthorized` turns off TLS certificate verification, making the connection vulnerable to man-in-the-middle attacks.

**Insecure:**
```javascript
const options = {
  hostname: 'api.example.com',
  rejectUnauthorized: false
};
```

**Secure:**
```javascript
const options = {
  hostname: 'api.example.com',
  rejectUnauthorized: true,
  ca: fs.readFileSync('/path/to/ca-cert.pem')
};
```

<a id="nodejs-node-tls-reject-unauthorized"></a>

### NODE_TLS_REJECT_UNAUTHORIZED

**ID:** `node-tls-reject-unauthorized` | **Severity:** CRITICAL

Setting `NODE_TLS_REJECT_UNAUTHORIZED=0` disables TLS verification process-wide, affecting every outbound connection.

**Insecure:**
```javascript
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
const res = await fetch('https://api.example.com/data');
```

**Secure:**
```javascript
// Remove the env var; configure per-request CA certificates instead
const agent = new https.Agent({ ca: fs.readFileSync('ca.pem') });
const res = await fetch('https://api.example.com/data', { agent });
```

<a id="nodejs-strict-ssl-false"></a>

### strictSSL: false

**ID:** `strict-ssl-false` | **Severity:** CRITICAL

Disabling `strictSSL` in the request/request-promise library skips certificate verification entirely.

**Insecure:**
```javascript
const response = await request({
  url: 'https://api.example.com',
  strictSSL: false
});
```

**Secure:**
```javascript
const response = await request({
  url: 'https://api.example.com',
  strictSSL: true,
  ca: fs.readFileSync('/path/to/ca-cert.pem')
});
```

<a id="nodejs-tlsv1-method"></a>

### TLSv1_method

**ID:** `tlsv1-method` | **Severity:** HIGH

TLS 1.0 has known vulnerabilities including POODLE and BEAST attacks. It was deprecated by RFC 8996.

**Insecure:**
```javascript
const server = tls.createServer({
  secureProtocol: 'TLSv1_method'
});
```

**Secure:**
```javascript
const server = tls.createServer({
  minVersion: 'TLSv1.2'
});
```

<a id="nodejs-tlsv11-method"></a>

### TLSv1_1_method

**ID:** `tlsv11-method` | **Severity:** HIGH

TLS 1.1 has known vulnerabilities and was deprecated by RFC 8996.

**Insecure:**
```javascript
const server = tls.createServer({
  secureProtocol: 'TLSv1_1_method'
});
```

**Secure:**
```javascript
const server = tls.createServer({
  minVersion: 'TLSv1.2'
});
```

<a id="nodejs-min-version-weak"></a>

### minVersion TLS 1.0/1.1

**ID:** `min-version-weak` | **Severity:** HIGH

Setting `minVersion` to TLS 1.0 or 1.1 permits connections using deprecated, vulnerable protocol versions.

**Insecure:**
```javascript
const server = tls.createServer({
  minVersion: 'TLSv1'
});
```

**Secure:**
```javascript
const server = tls.createServer({
  minVersion: 'TLSv1.2'
});
```

<a id="nodejs-weak-cipher-config"></a>

### Weak cipher configuration

**ID:** `weak-cipher-config` | **Severity:** HIGH

Configuring weak or broken ciphers (DES, RC4, NULL, EXPORT) exposes connections to known cryptographic attacks.

**Insecure:**
```javascript
const server = tls.createServer({
  ciphers: 'DES-CBC3-SHA:RC4-SHA:AES128-SHA'
});
```

**Secure:**
```javascript
const server = tls.createServer({
  ciphers: tls.DEFAULT_CIPHERS,
  honorCipherOrder: true
});
```

<a id="nodejs-secure-protocol-weak"></a>

### Weak secureProtocol

**ID:** `secure-protocol-weak` | **Severity:** HIGH

Using a weak `secureProtocol` value forces the server to negotiate with an obsolete TLS version.

**Insecure:**
```javascript
const options = {
  secureProtocol: 'TLSv1_method',
  key: fs.readFileSync('key.pem')
};
```

**Secure:**
```javascript
const options = {
  minVersion: 'TLSv1.2',
  key: fs.readFileSync('key.pem')
};
```

<a id="nodejs-max-version-tlsv12"></a>

### maxVersion TLSv1.2

**ID:** `max-version-tlsv12` | **Severity:** MEDIUM

Capping `maxVersion` at TLS 1.2 prevents negotiation of TLS 1.3, which offers improved security and performance.

**Insecure:**
```javascript
const server = tls.createServer({
  maxVersion: 'TLSv1.2'
});
```

**Secure:**
```javascript
const server = tls.createServer({
  minVersion: 'TLSv1.2'
  // Allow TLS 1.3 by not capping maxVersion
});
```

<a id="nodejs-honor-cipher-order-false"></a>

### honorCipherOrder disabled

**ID:** `honor-cipher-order-false` | **Severity:** MEDIUM

When `honorCipherOrder` is false, the client chooses the cipher, allowing it to select a weaker option the server would not prefer.

**Insecure:**
```javascript
const server = tls.createServer({
  honorCipherOrder: false,
  ciphers: 'ECDHE-RSA-AES128-GCM-SHA256'
});
```

**Secure:**
```javascript
const server = tls.createServer({
  honorCipherOrder: true,
  ciphers: 'ECDHE-RSA-AES128-GCM-SHA256'
});
```

<a id="nodejs-axios-defaults-httpsagent"></a>

### axios defaults httpsAgent

**ID:** `axios-defaults-httpsagent` | **Severity:** MEDIUM

Overriding `axios.defaults.httpsAgent` globally affects every request made through axios. Review the agent's TLS settings carefully.

**Insecure:**
```javascript
axios.defaults.httpsAgent = new https.Agent({
  rejectUnauthorized: false
});
```

**Secure:**
```javascript
const secureAgent = new https.Agent({
  ca: fs.readFileSync('/path/to/ca-cert.pem')
});
const client = axios.create({ httpsAgent: secureAgent });
```

<a id="nodejs-min-version-tlsv13"></a>

### minVersion TLSv1.3

**ID:** `min-version-tlsv13` | **Severity:** INFO

> **Informational.** Requiring TLS 1.3 as the minimum version provides the strongest security but may reject clients that only support TLS 1.2. Verify that all connecting clients support TLS 1.3 before enforcing this.

## C++

<a id="cpp-ssl-ctx-verify-none"></a>

### SSL_CTX_set_verify SSL_VERIFY_NONE

**ID:** `ssl-ctx-verify-none` | **Severity:** CRITICAL

Passing `SSL_VERIFY_NONE` to `SSL_CTX_set_verify` disables certificate verification on the context, making all connections from it vulnerable to man-in-the-middle attacks.

**Insecure:**
```cpp
SSL_CTX *ctx = SSL_CTX_new(TLS_client_method());
SSL_CTX_set_verify(ctx, SSL_VERIFY_NONE, nullptr);
```

**Secure:**
```cpp
SSL_CTX *ctx = SSL_CTX_new(TLS_client_method());
SSL_CTX_set_verify(ctx, SSL_VERIFY_PEER, nullptr);
SSL_CTX_load_verify_locations(ctx, "/path/to/ca-cert.pem", nullptr);
```

<a id="cpp-ssl-set-verify-none"></a>

### SSL_set_verify SSL_VERIFY_NONE

**ID:** `ssl-set-verify-none` | **Severity:** CRITICAL

Passing `SSL_VERIFY_NONE` to `SSL_set_verify` disables certificate verification on an individual SSL connection, exposing it to interception.

**Insecure:**
```cpp
SSL *ssl = SSL_new(ctx);
SSL_set_verify(ssl, SSL_VERIFY_NONE, nullptr);
```

**Secure:**
```cpp
SSL *ssl = SSL_new(ctx);
SSL_set_verify(ssl, SSL_VERIFY_PEER, nullptr);
```

<a id="cpp-curl-ssl-verifypeer-off"></a>

### CURLOPT_SSL_VERIFYPEER disabled

**ID:** `curl-ssl-verifypeer-off` | **Severity:** CRITICAL

Disabling `CURLOPT_SSL_VERIFYPEER` tells libcurl to skip verifying the server's certificate, allowing any certificate to be accepted.

**Insecure:**
```cpp
CURL *curl = curl_easy_init();
curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0);
```

**Secure:**
```cpp
CURL *curl = curl_easy_init();
curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 1L);
curl_easy_setopt(curl, CURLOPT_CAINFO, "/path/to/ca-bundle.crt");
```

<a id="cpp-curl-ssl-verifyhost-off"></a>

### CURLOPT_SSL_VERIFYHOST disabled

**ID:** `curl-ssl-verifyhost-off` | **Severity:** CRITICAL

Disabling `CURLOPT_SSL_VERIFYHOST` tells libcurl to skip verifying that the server certificate matches the hostname, enabling impersonation attacks.

**Insecure:**
```cpp
CURL *curl = curl_easy_init();
curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0);
```

**Secure:**
```cpp
CURL *curl = curl_easy_init();
curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 2L);
curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 1L);
```

<a id="cpp-tls1-version"></a>

### TLS1_VERSION

**ID:** `tls1-version` | **Severity:** HIGH

TLS 1.0 has known vulnerabilities including POODLE and BEAST attacks. It was deprecated by RFC 8996.

**Insecure:**
```cpp
SSL_CTX *ctx = SSL_CTX_new(TLS_client_method());
SSL_CTX_set_min_proto_version(ctx, TLS1_VERSION);
```

**Secure:**
```cpp
SSL_CTX *ctx = SSL_CTX_new(TLS_client_method());
SSL_CTX_set_min_proto_version(ctx, TLS1_2_VERSION);
```

<a id="cpp-tls11-version"></a>

### TLS1_1_VERSION

**ID:** `tls11-version` | **Severity:** HIGH

TLS 1.1 has known vulnerabilities and was deprecated by RFC 8996.

**Insecure:**
```cpp
SSL_CTX *ctx = SSL_CTX_new(TLS_client_method());
SSL_CTX_set_min_proto_version(ctx, TLS1_1_VERSION);
```

**Secure:**
```cpp
SSL_CTX *ctx = SSL_CTX_new(TLS_client_method());
SSL_CTX_set_min_proto_version(ctx, TLS1_2_VERSION);
```

<a id="cpp-sslv3-method"></a>

### SSLv3_method

**ID:** `sslv3-method` | **Severity:** HIGH

SSL 3.0 is completely broken by the POODLE attack and must not be used. The `SSLv3_method` function is removed in modern OpenSSL builds.

**Insecure:**
```cpp
SSL_CTX *ctx = SSL_CTX_new(SSLv3_method());
```

**Secure:**
```cpp
SSL_CTX *ctx = SSL_CTX_new(TLS_client_method());
SSL_CTX_set_min_proto_version(ctx, TLS1_2_VERSION);
```

<a id="cpp-tlsv1-method"></a>

### TLSv1_method

**ID:** `tlsv1-method` | **Severity:** HIGH

`TLSv1_method` pins the connection to TLS 1.0, which has known vulnerabilities and is deprecated.

**Insecure:**
```cpp
SSL_CTX *ctx = SSL_CTX_new(TLSv1_method());
```

**Secure:**
```cpp
SSL_CTX *ctx = SSL_CTX_new(TLS_client_method());
SSL_CTX_set_min_proto_version(ctx, TLS1_2_VERSION);
```

<a id="cpp-weak-cipher-list"></a>

### Weak OpenSSL cipher list

**ID:** `weak-cipher-list` | **Severity:** HIGH

Configuring weak ciphers (DES, RC4, NULL, EXPORT, eNULL, aNULL) via `SSL_CTX_set_cipher_list` exposes connections to known cryptographic attacks.

**Insecure:**
```cpp
SSL_CTX_set_cipher_list(ctx, "DES-CBC3-SHA:RC4-SHA:AES128-SHA");
```

**Secure:**
```cpp
SSL_CTX_set_cipher_list(ctx, "ECDHE+AESGCM:ECDHE+CHACHA20:DHE+AESGCM");
```

<a id="cpp-weak-ciphersuites"></a>

### Weak TLS 1.3 ciphersuites

**ID:** `weak-ciphersuites` | **Severity:** HIGH

Setting weak ciphersuites via `SSL_CTX_set_ciphersuites` undermines TLS 1.3 security. Use only the standard AEAD ciphersuites.

**Insecure:**
```cpp
SSL_CTX_set_ciphersuites(ctx, "TLS_AES_128_GCM_SHA256:NULL-SHA256");
```

**Secure:**
```cpp
SSL_CTX_set_ciphersuites(ctx,
    "TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256");
```

<a id="cpp-max-proto-tls12"></a>

### SSL_CTX_set_max_proto_version TLS1_2

**ID:** `max-proto-tls12` | **Severity:** MEDIUM

Capping the maximum protocol version at TLS 1.2 prevents negotiation of TLS 1.3, which offers improved security and performance.

**Insecure:**
```cpp
SSL_CTX *ctx = SSL_CTX_new(TLS_client_method());
SSL_CTX_set_max_proto_version(ctx, TLS1_2_VERSION);
```

**Secure:**
```cpp
SSL_CTX *ctx = SSL_CTX_new(TLS_client_method());
SSL_CTX_set_min_proto_version(ctx, TLS1_2_VERSION);
// Allow TLS 1.3 by not capping the max version
```

<a id="cpp-min-proto-tls13"></a>

### SSL_CTX_set_min_proto_version TLS1_3

**ID:** `min-proto-tls13` | **Severity:** INFO

> **Informational.** Requiring TLS 1.3 as the minimum version provides the strongest security but may reject clients or servers that only support TLS 1.2. Verify that all peers support TLS 1.3 before enforcing this.

## Java

<a id="java-allow-all-hostname-verifier"></a>

### ALLOW_ALL HostnameVerifier

**ID:** `allow-all-hostname-verifier` | **Severity:** CRITICAL

Using `ALLOW_ALL` or a custom `HostnameVerifier` that returns `true` disables hostname verification, allowing any certificate to be accepted regardless of the host it was issued for. This enables man-in-the-middle attacks.

**Insecure:**
```java
HttpsURLConnection conn = (HttpsURLConnection) url.openConnection();
conn.setHostnameVerifier(SSLSocketFactory.ALLOW_ALL_HOSTNAME_VERIFIER);
```

**Secure:**
```java
HttpsURLConnection conn = (HttpsURLConnection) url.openConnection();
// Uses the default HostnameVerifier which validates against the certificate
conn.connect();
```

<a id="java-trust-all-certs"></a>

### TrustAllCerts / permissive TrustManager

**ID:** `trust-all-certs` | **Severity:** CRITICAL

A custom `X509TrustManager` with an empty `checkServerTrusted` method accepts any certificate, completely disabling certificate verification and enabling man-in-the-middle attacks.

**Insecure:**
```java
TrustManager[] trustAll = new TrustManager[] {
    new X509TrustManager() {
        public void checkServerTrusted(X509Certificate[] chain, String auth) {}
        public X509Certificate[] getAcceptedIssuers() { return null; }
    }
};
SSLContext ctx = SSLContext.getInstance("TLS");
ctx.init(null, trustAll, null);
```

**Secure:**
```java
SSLContext ctx = SSLContext.getInstance("TLSv1.2");
// Uses default TrustManager which validates against the system trust store
ctx.init(null, null, null);
```

<a id="java-custom-ssl-socket-factory"></a>

### setSSLSocketFactory bypass

**ID:** `custom-ssl-socket-factory` | **Severity:** CRITICAL

Setting a custom `SSLSocketFactory` can bypass the default certificate and hostname verification. Unless the factory is carefully configured, this opens the connection to man-in-the-middle attacks.

**Insecure:**
```java
HttpsURLConnection conn = (HttpsURLConnection) url.openConnection();
conn.setSSLSocketFactory(permissiveContext.getSocketFactory());
```

**Secure:**
```java
HttpsURLConnection conn = (HttpsURLConnection) url.openConnection();
// Uses the JVM's default SSLSocketFactory with proper verification
conn.connect();
```

<a id="java-noop-hostname-verifier"></a>

### NoopHostnameVerifier

**ID:** `noop-hostname-verifier` | **Severity:** CRITICAL

Apache HttpClient's `NoopHostnameVerifier` accepts any hostname, allowing certificates issued for one domain to be used for another. This enables man-in-the-middle attacks.

**Insecure:**
```java
CloseableHttpClient client = HttpClients.custom()
    .setSSLHostnameVerifier(NoopHostnameVerifier.INSTANCE)
    .build();
```

**Secure:**
```java
CloseableHttpClient client = HttpClients.custom()
    .setSSLHostnameVerifier(new DefaultHostnameVerifier())
    .build();
```

<a id="java-trust-all-strategy"></a>

### TrustAllStrategy / TrustSelfSignedStrategy

**ID:** `trust-all-strategy` | **Severity:** CRITICAL

Apache HttpClient's `TrustAllStrategy` trusts every certificate unconditionally. `TrustSelfSignedStrategy` additionally trusts self-signed certificates, which cannot be revoked and have no chain of trust.

**Insecure:**
```java
SSLContext sslCtx = SSLContextBuilder.create()
    .loadTrustMaterial(TrustAllStrategy.INSTANCE)
    .build();
CloseableHttpClient client = HttpClients.custom()
    .setSSLContext(sslCtx)
    .build();
```

**Secure:**
```java
SSLContext sslCtx = SSLContextBuilder.create()
    .loadTrustMaterial(trustStore, null)
    .build();
CloseableHttpClient client = HttpClients.custom()
    .setSSLContext(sslCtx)
    .build();
```

<a id="java-okhttp-ssl-socket-factory"></a>

### OkHttp sslSocketFactory

**ID:** `okhttp-ssl-socket-factory` | **Severity:** CRITICAL

Setting a custom `sslSocketFactory` on an OkHttp client may bypass certificate verification if the underlying `SSLContext` or `TrustManager` is permissive.

**Insecure:**
```java
OkHttpClient client = new OkHttpClient.Builder()
    .sslSocketFactory(permissiveCtx.getSocketFactory(), trustAllMgr)
    .hostnameVerifier((h, s) -> true)
    .build();
```

**Secure:**
```java
OkHttpClient client = new OkHttpClient.Builder()
    // Uses default SSL configuration with system trust store
    .build();
```

<a id="java-unversioned-ssl-context"></a>

### SSLContext.getInstance TLS unversioned

**ID:** `unversioned-ssl-context` | **Severity:** HIGH

`SSLContext.getInstance("TLS")` without a version suffix defaults to the oldest supported TLS version on the platform, which may include TLS 1.0 or 1.1. Always specify a minimum version explicitly.

**Insecure:**
```java
SSLContext ctx = SSLContext.getInstance("TLS");
ctx.init(null, null, null);
```

**Secure:**
```java
SSLContext ctx = SSLContext.getInstance("TLSv1.2");
ctx.init(null, null, null);
```

<a id="java-sslcontext-tlsv1"></a>

### SSLContext.getInstance TLSv1

**ID:** `sslcontext-tlsv1` | **Severity:** HIGH

TLS 1.0 has known vulnerabilities including POODLE and BEAST. It was deprecated by RFC 8996 in 2021. Use TLS 1.2 or later.

**Insecure:**
```java
SSLContext ctx = SSLContext.getInstance("TLSv1");
```

**Secure:**
```java
SSLContext ctx = SSLContext.getInstance("TLSv1.2");
```

<a id="java-sslcontext-tlsv11"></a>

### SSLContext.getInstance TLSv1.1

**ID:** `sslcontext-tlsv11` | **Severity:** HIGH

TLS 1.1 has known vulnerabilities and was deprecated by RFC 8996 in 2021. Use TLS 1.2 or later.

**Insecure:**
```java
SSLContext ctx = SSLContext.getInstance("TLSv1.1");
```

**Secure:**
```java
SSLContext ctx = SSLContext.getInstance("TLSv1.2");
```

<a id="java-weak-cipher-suite"></a>

### Weak JSSE cipher suite

**ID:** `weak-cipher-suite` | **Severity:** HIGH

Cipher suites using DES, RC4, NULL, EXPORT, or anonymous key exchange are cryptographically broken or provide no encryption at all. These must not be enabled.

**Insecure:**
```java
SSLSocket socket = (SSLSocket) factory.createSocket(host, port);
socket.setEnabledCipherSuites(new String[] {
    "SSL_RSA_WITH_RC4_128_MD5", "SSL_RSA_WITH_DES_CBC_SHA"
});
```

**Secure:**
```java
SSLSocket socket = (SSLSocket) factory.createSocket(host, port);
socket.setEnabledCipherSuites(new String[] {
    "TLS_AES_256_GCM_SHA384", "TLS_AES_128_GCM_SHA256"
});
```

<a id="java-apache-httpclient-custom-ssl"></a>

### Apache HttpClient custom SSLContext

**ID:** `apache-httpclient-custom-ssl` | **Severity:** HIGH

Providing a custom `SSLContext` to Apache HttpClient bypasses the default trust configuration. Review the context to ensure it validates certificates against a proper trust store.

**Insecure:**
```java
SSLContext ctx = SSLContext.getInstance("TLS");
ctx.init(null, trustAll, null);
CloseableHttpClient client = HttpClients.custom()
    .setSSLContext(ctx)
    .build();
```

**Secure:**
```java
SSLContext ctx = SSLContext.getInstance("TLSv1.2");
ctx.init(null, null, null); // default TrustManager
CloseableHttpClient client = HttpClients.custom()
    .setSSLContext(ctx)
    .build();
```

<a id="java-ssl-connection-socket-factory"></a>

### SSLConnectionSocketFactory

**ID:** `ssl-connection-socket-factory` | **Severity:** HIGH

A custom `SSLConnectionSocketFactory` can override protocol and cipher selection. Review to ensure it does not allow weak protocols or disable hostname verification.

**Insecure:**
```java
SSLConnectionSocketFactory sf = new SSLConnectionSocketFactory(
    sslContext, NoopHostnameVerifier.INSTANCE);
CloseableHttpClient client = HttpClients.custom()
    .setSSLSocketFactory(sf).build();
```

**Secure:**
```java
SSLConnectionSocketFactory sf = new SSLConnectionSocketFactory(
    sslContext, new String[] {"TLSv1.2", "TLSv1.3"}, null,
    SSLConnectionSocketFactory.getDefaultHostnameVerifier());
CloseableHttpClient client = HttpClients.custom()
    .setSSLSocketFactory(sf).build();
```

<a id="java-enabled-weak-protocols"></a>

### setEnabledProtocols weak TLS

**ID:** `enabled-weak-protocols` | **Severity:** MEDIUM

Explicitly enabling TLS 1.0 or TLS 1.1 via `setEnabledProtocols` allows connections over deprecated protocols with known vulnerabilities.

**Insecure:**
```java
SSLSocket socket = (SSLSocket) factory.createSocket(host, port);
socket.setEnabledProtocols(new String[] {"TLSv1", "TLSv1.1", "TLSv1.2"});
```

**Secure:**
```java
SSLSocket socket = (SSLSocket) factory.createSocket(host, port);
socket.setEnabledProtocols(new String[] {"TLSv1.2", "TLSv1.3"});
```

<a id="java-ssl-socket-factory-default"></a>

### Default SSLSocketFactory

**ID:** `ssl-socket-factory-default` | **Severity:** MEDIUM

`SSLSocketFactory.getDefault()` returns a factory whose protocol and cipher configuration depends on the JVM's defaults, which may include weak ciphers or protocols on older runtimes.

**Insecure:**
```java
SSLSocketFactory factory = (SSLSocketFactory) SSLSocketFactory.getDefault();
SSLSocket socket = (SSLSocket) factory.createSocket(host, port);
```

**Secure:**
```java
SSLContext ctx = SSLContext.getInstance("TLSv1.2");
ctx.init(null, null, null);
SSLSocketFactory factory = ctx.getSocketFactory();
SSLSocket socket = (SSLSocket) factory.createSocket(host, port);
```

<a id="java-sslcontext-tlsv13"></a>

### SSLContext.getInstance TLSv1.3

**ID:** `sslcontext-tlsv13` | **Severity:** INFO

> **Informational.** Forcing TLS 1.3 exclusively may break connectivity with older clients or servers that only support TLS 1.2. This is not a vulnerability but should be a conscious decision.

<a id="java-pqc-ml-kem"></a>

### PQC/ML-KEM patterns

**ID:** `pqc-ml-kem` | **Severity:** INFO

> **Informational.** Post-Quantum Cryptography (ML-KEM / Kyber) usage detected. This indicates proactive adoption of quantum-resistant key encapsulation. No action required.

## Rust

<a id="rust-danger-accept-invalid-certs"></a>

### danger_accept_invalid_certs

**ID:** `danger-accept-invalid-certs` | **Severity:** CRITICAL

Calling `danger_accept_invalid_certs(true)` on a reqwest client disables all certificate verification, accepting expired, self-signed, and otherwise invalid certificates. This enables man-in-the-middle attacks.

**Insecure:**
```rust
let client = reqwest::Client::builder()
    .danger_accept_invalid_certs(true)
    .build()?;
```

**Secure:**
```rust
let client = reqwest::Client::builder()
    .build()?;
// Default configuration validates certificates
```

<a id="rust-danger-accept-invalid-hostnames"></a>

### danger_accept_invalid_hostnames

**ID:** `danger-accept-invalid-hostnames` | **Severity:** CRITICAL

Calling `danger_accept_invalid_hostnames(true)` disables hostname verification, allowing a valid certificate for one domain to be accepted for any other domain.

**Insecure:**
```rust
let client = reqwest::Client::builder()
    .danger_accept_invalid_hostnames(true)
    .build()?;
```

**Secure:**
```rust
let client = reqwest::Client::builder()
    .build()?;
// Default configuration validates hostnames
```

<a id="rust-openssl-verify-none"></a>

### SslVerifyMode::NONE

**ID:** `openssl-verify-none` | **Severity:** CRITICAL

Setting the verify mode to `SslVerifyMode::NONE` disables all certificate verification in the openssl crate, making the connection vulnerable to man-in-the-middle attacks.

**Insecure:**
```rust
let mut ctx = SslConnector::builder(SslMethod::tls())?;
ctx.set_verify(SslVerifyMode::NONE);
```

**Secure:**
```rust
let mut ctx = SslConnector::builder(SslMethod::tls())?;
ctx.set_verify(SslVerifyMode::PEER);
```

<a id="rust-rustls-dangerous-verifier"></a>

### Custom dangerous ServerCertVerifier

**ID:** `rustls-dangerous-verifier` | **Severity:** CRITICAL

Implementing a custom `ServerCertVerifier` that returns `ServerCertVerified::assertion()` bypasses certificate chain validation entirely. This is equivalent to disabling TLS verification.

**Insecure:**
```rust
impl ServerCertVerifier for NoVerifier {
    fn verify_server_cert(&self, ...) -> Result<ServerCertVerified, Error> {
        Ok(ServerCertVerified::assertion())
    }
}
```

**Secure:**
```rust
use rustls::RootCertStore;
let mut root_store = RootCertStore::empty();
root_store.extend(webpki_roots::TLS_SERVER_ROOTS.iter().cloned());
let config = rustls::ClientConfig::builder()
    .with_root_certificates(root_store)
    .with_no_client_auth();
```

<a id="rust-openssl-no-hostname-verify"></a>

### Hostname verification disabled

**ID:** `openssl-no-hostname-verify` | **Severity:** CRITICAL

Calling `set_verify_hostname(false)` disables hostname verification, allowing a certificate valid for one domain to be accepted for any other. This enables man-in-the-middle attacks.

**Insecure:**
```rust
let mut ssl = SslConnector::builder(SslMethod::tls())?;
ssl.set_verify_hostname(false);
```

**Secure:**
```rust
let mut ssl = SslConnector::builder(SslMethod::tls())?;
// Hostname verification is enabled by default
```

<a id="rust-native-tls-proto-tlsv10"></a>

### Protocol::Tlsv10

**ID:** `native-tls-proto-tlsv10` | **Severity:** HIGH

TLS 1.0 has known vulnerabilities including POODLE and BEAST and was deprecated by RFC 8996 in 2021. Use TLS 1.2 or later.

**Insecure:**
```rust
let connector = TlsConnector::builder()
    .min_protocol_version(Some(Protocol::Tlsv10))
    .build()?;
```

**Secure:**
```rust
let connector = TlsConnector::builder()
    .min_protocol_version(Some(Protocol::Tlsv12))
    .build()?;
```

<a id="rust-native-tls-proto-tlsv11"></a>

### Protocol::Tlsv11

**ID:** `native-tls-proto-tlsv11` | **Severity:** HIGH

TLS 1.1 has known vulnerabilities and was deprecated by RFC 8996 in 2021. Use TLS 1.2 or later.

**Insecure:**
```rust
let connector = TlsConnector::builder()
    .min_protocol_version(Some(Protocol::Tlsv11))
    .build()?;
```

**Secure:**
```rust
let connector = TlsConnector::builder()
    .min_protocol_version(Some(Protocol::Tlsv12))
    .build()?;
```

<a id="rust-openssl-ssl3"></a>

### SSL 3.0 protocol

**ID:** `openssl-ssl3` | **Severity:** HIGH

SSL 3.0 is fundamentally broken (POODLE attack) and must not be used. It has been deprecated since 2015 (RFC 7568).

**Insecure:**
```rust
let mut ctx = SslConnector::builder(SslMethod::tls())?;
ctx.set_min_proto_version(Some(SslVersion::SSL3))?;
```

**Secure:**
```rust
let mut ctx = SslConnector::builder(SslMethod::tls())?;
ctx.set_min_proto_version(Some(SslVersion::TLS1_2))?;
```

<a id="rust-openssl-weak-cipher"></a>

### Weak cipher in cipher list

**ID:** `openssl-weak-cipher` | **Severity:** HIGH

Cipher suites using DES, RC4, NULL, or EXPORT-grade cryptography are broken. These must not appear in the cipher list.

**Insecure:**
```rust
let mut ctx = SslConnector::builder(SslMethod::tls())?;
ctx.set_cipher_list("RC4-SHA:DES-CBC3-SHA:AES128-SHA")?;
```

**Secure:**
```rust
let mut ctx = SslConnector::builder(SslMethod::tls())?;
ctx.set_cipher_list("ECDHE+AESGCM:ECDHE+CHACHA20:DHE+AESGCM")?;
```

<a id="rust-min-tls-version-weak"></a>

### Weak minimum TLS version

**ID:** `min-tls-version-weak` | **Severity:** HIGH

Setting the minimum TLS version to 1.0 or 1.1 allows connections over deprecated protocols with known vulnerabilities.

**Insecure:**
```rust
let config = rustls::ClientConfig::builder()
    .with_safe_default_cipher_suites()
    .with_safe_default_kx_groups();
// min_tls_version set to TLS_1_0
```

**Secure:**
```rust
let config = rustls::ClientConfig::builder();
// rustls defaults to TLS 1.2 minimum
```

<a id="rust-max-version-tls12"></a>

### Max TLS version capped at 1.2

**ID:** `max-version-tls12` | **Severity:** MEDIUM

Capping the maximum TLS version at 1.2 prevents adoption of TLS 1.3, which offers improved security and performance through mandatory forward secrecy and a simplified handshake.

**Insecure:**
```rust
let connector = TlsConnector::builder()
    .max_protocol_version(Some(Protocol::Tlsv12))
    .build()?;
```

**Secure:**
```rust
let connector = TlsConnector::builder()
    .min_protocol_version(Some(Protocol::Tlsv12))
    // No max version cap; allows TLS 1.3
    .build()?;
```

<a id="rust-custom-cipher-list"></a>

### Custom cipher list config

**ID:** `custom-cipher-list` | **Severity:** MEDIUM

Custom cipher configuration overrides the library defaults, which are generally well-maintained. Review custom lists to ensure they do not include weak ciphers or exclude strong ones.

**Insecure:**
```rust
let mut ctx = SslConnector::builder(SslMethod::tls())?;
ctx.set_cipher_list("ALL:!aNULL")?;
```

**Secure:**
```rust
let mut ctx = SslConnector::builder(SslMethod::tls())?;
// Use library defaults or a curated modern list
ctx.set_cipher_list("ECDHE+AESGCM:ECDHE+CHACHA20:DHE+AESGCM")?;
```

<a id="rust-min-version-tls13"></a>

### Forces TLS 1.3 only

**ID:** `min-version-tls13` | **Severity:** INFO

> **Informational.** Requiring TLS 1.3 as the minimum version may break connectivity with older clients or servers that only support TLS 1.2. This is not a vulnerability but should be a conscious decision.

<a id="rust-pqc-ml-kem"></a>

### PQC/ML-KEM patterns

**ID:** `pqc-ml-kem` | **Severity:** INFO

> **Informational.** Post-Quantum Cryptography (ML-KEM / Kyber) usage detected. This indicates proactive adoption of quantum-resistant key encapsulation. No action required.
