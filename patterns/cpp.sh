#!/usr/bin/env bash
# cpp.sh - C++ TLS pattern definitions
# Format: "id|name|description|regex"

# shellcheck disable=SC2034  # Array is used by scanner.sh via eval
CPP_PATTERNS=(
	"ssl-ctx-verify-none|SSL_CTX_set_verify SSL_VERIFY_NONE|Disables TLS certificate verification (MITM vulnerability)|SSL_CTX_set_verify.*SSL_VERIFY_NONE"
	"ssl-set-verify-none|SSL_set_verify SSL_VERIFY_NONE|Disables TLS certificate verification (MITM vulnerability)|SSL_set_verify.*SSL_VERIFY_NONE"
	"tls1-version|TLS1_VERSION|TLS 1.0 has known vulnerabilities (POODLE, BEAST)|TLS1_VERSION[^_]"
	"tls11-version|TLS1_1_VERSION|TLS 1.1 has known vulnerabilities|TLS1_1_VERSION"
	"sslv3-method|SSLv3_method|SSL 3.0 has known vulnerabilities (POODLE)|SSLv3_method"
	"tlsv1-method|TLSv1_method|TLS 1.0 has known vulnerabilities|TLSv1_method[^_]"
)
