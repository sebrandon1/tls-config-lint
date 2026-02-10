#!/usr/bin/env bash
# cpp.sh - C++ TLS pattern definitions
# Format: "id|severity|name|description|regex"

# shellcheck disable=SC2034  # Array is used by scanner.sh via eval
CPP_PATTERNS=(
	"ssl-ctx-verify-none|CRITICAL|SSL_CTX_set_verify SSL_VERIFY_NONE|Disables TLS certificate verification (MITM vulnerability)|SSL_CTX_set_verify.*SSL_VERIFY_NONE"
	"ssl-set-verify-none|CRITICAL|SSL_set_verify SSL_VERIFY_NONE|Disables TLS certificate verification (MITM vulnerability)|SSL_set_verify.*SSL_VERIFY_NONE"
	"tls1-version|HIGH|TLS1_VERSION|TLS 1.0 has known vulnerabilities (POODLE, BEAST)|TLS1_VERSION[^_]"
	"tls11-version|HIGH|TLS1_1_VERSION|TLS 1.1 has known vulnerabilities|TLS1_1_VERSION"
	"sslv3-method|HIGH|SSLv3_method|SSL 3.0 has known vulnerabilities (POODLE)|SSLv3_method"
	"tlsv1-method|HIGH|TLSv1_method|TLS 1.0 has known vulnerabilities|TLSv1_method[^_]"
	"max-proto-tls12|MEDIUM|SSL_CTX_set_max_proto_version TLS1_2|Caps maximum TLS version at 1.2|SSL_CTX_set_max_proto_version.*TLS1_2_VERSION"
	"min-proto-tls13|INFO|SSL_CTX_set_min_proto_version TLS1_3|Forces TLS 1.3 (may break older clients)|SSL_CTX_set_min_proto_version.*TLS1_3_VERSION"
)
