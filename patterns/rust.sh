#!/usr/bin/env bash
# rust.sh - Rust TLS pattern definitions
# Format: "id|severity|name|description|regex"

# shellcheck disable=SC2034  # Array is used by scanner.sh via eval
RUST_PATTERNS=(
	"danger-accept-invalid-certs|CRITICAL|danger_accept_invalid_certs|Disables certificate verification (MITM vulnerability)|danger_accept_invalid_certs\(true\)|tls_danger_accept_invalid_certs\(true\)"
	"danger-accept-invalid-hostnames|CRITICAL|danger_accept_invalid_hostnames|Disables hostname verification (MITM vulnerability)|danger_accept_invalid_hostnames\(true\)|tls_danger_accept_invalid_hostnames\(true\)"
	"openssl-verify-none|CRITICAL|SslVerifyMode::NONE|Disables SSL certificate verification (MITM vulnerability)|SslVerifyMode::NONE"
	"rustls-dangerous-verifier|CRITICAL|Custom dangerous ServerCertVerifier|Bypasses certificate verification with custom verifier|impl[[:space:]].*ServerCertVerifier|ServerCertVerified::assertion"
	"openssl-no-hostname-verify|CRITICAL|Hostname verification disabled|Disables hostname verification (MITM vulnerability)|set_verify_hostname[[:space:]]*\(false\)"
	"native-tls-proto-tlsv10|HIGH|Protocol::Tlsv10|TLS 1.0 has known vulnerabilities (POODLE, BEAST)|Protocol::Tlsv10"
	"native-tls-proto-tlsv11|HIGH|Protocol::Tlsv11|TLS 1.1 has known vulnerabilities|Protocol::Tlsv11"
	"openssl-ssl3|HIGH|SSL 3.0 protocol|SSL 3.0 is insecure and should not be used|SslVersion::SSL3"
	"openssl-weak-cipher|HIGH|Weak cipher in cipher list|Weak or insecure cipher suites enabled|set_cipher_list.*(DES|RC4|NULL|EXPORT)"
	"min-tls-version-weak|HIGH|Weak minimum TLS version|Minimum TLS version allows insecure protocols|min_tls_version.*TLS_1_0|min_tls_version.*TLS_1_1|set_min_proto_version.*TLS1[^_2-9]"
	"max-version-tls12|MEDIUM|Max TLS version capped at 1.2|Prevents TLS 1.3 adoption|max_tls_version.*TLS_1_2|set_max_proto_version.*TLS1_2|max_protocol_version.*Tlsv12"
	"custom-cipher-list|MEDIUM|Custom cipher list config|Custom cipher configuration should be reviewed|set_cipher_list[[:space:]]*\(|set_ciphersuites[[:space:]]*\("
	"min-version-tls13|INFO|Forces TLS 1.3 only|May break compatibility with older clients|min_tls_version.*TLS_1_3|min_protocol_version.*Tlsv13|set_min_proto_version.*TLS1_3"
	"pqc-ml-kem|INFO|PQC/ML-KEM patterns|Post-Quantum Cryptography adoption (ML-KEM)|rustls_post_quantum|X25519MLKEM|MLKEM|ml.kem|pqc_kyber|post_quantum"
)
