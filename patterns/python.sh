#!/usr/bin/env bash
# python.sh - Python TLS pattern definitions
# Format: "id|name|description|regex"

# shellcheck disable=SC2034  # Array is used by scanner.sh via eval
PYTHON_PATTERNS=(
	"verify-false|verify=False|Disables TLS certificate verification (MITM vulnerability)|verify[[:space:]]*=[[:space:]]*False"
	"cert-none|ssl.CERT_NONE|Disables certificate verification via ssl module|CERT_NONE"
	"create-unverified-context|_create_unverified_context|Creates SSL context without certificate verification|_create_unverified_context"
	"check-hostname-false|check_hostname = False|Disables hostname verification|check_hostname[[:space:]]*=[[:space:]]*False"
	"protocol-tlsv1|PROTOCOL_TLSv1 (1.0)|TLS 1.0 has known vulnerabilities (POODLE, BEAST)|PROTOCOL_TLSv1[^_]"
	"protocol-tlsv11|PROTOCOL_TLSv1_1|TLS 1.1 has known vulnerabilities|PROTOCOL_TLSv1_1"
)
