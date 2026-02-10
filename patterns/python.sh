#!/usr/bin/env bash
# python.sh - Python TLS pattern definitions
# Format: "id|severity|name|description|regex"

PYTHON_PATTERNS=(
	"verify-false|CRITICAL|verify=False|Disables TLS certificate verification (MITM vulnerability)|verify[[:space:]]*=[[:space:]]*False"
	"cert-none|CRITICAL|ssl.CERT_NONE|Disables certificate verification via ssl module|CERT_NONE"
	"create-unverified-context|CRITICAL|_create_unverified_context|Creates SSL context without certificate verification|_create_unverified_context"
	"check-hostname-false|CRITICAL|check_hostname = False|Disables hostname verification|check_hostname[[:space:]]*=[[:space:]]*False"
	"protocol-tlsv1|HIGH|PROTOCOL_TLSv1 (1.0)|TLS 1.0 has known vulnerabilities (POODLE, BEAST)|PROTOCOL_TLSv1[^_]"
	"protocol-tlsv11|HIGH|PROTOCOL_TLSv1_1|TLS 1.1 has known vulnerabilities|PROTOCOL_TLSv1_1"
	"max-version-tlsv12|MEDIUM|maximum_version TLSv1_2|Caps maximum TLS version at 1.2, preventing TLS 1.3|maximum_version.*TLSv1_2"
	"min-version-tlsv13|INFO|minimum_version TLSv1_3|Forces TLS 1.3 (may break older clients)|minimum_version.*TLSv1_3"
)
