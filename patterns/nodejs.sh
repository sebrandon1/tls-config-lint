#!/usr/bin/env bash
# nodejs.sh - Node.js/TypeScript TLS pattern definitions
# Format: "id|name|description|regex"

# shellcheck disable=SC2034  # Array is used by scanner.sh via eval
NODEJS_PATTERNS=(
	"reject-unauthorized-false|rejectUnauthorized: false|Disables TLS certificate verification (MITM vulnerability)|rejectUnauthorized[[:space:]]*:[[:space:]]*false"
	"node-tls-reject-unauthorized|NODE_TLS_REJECT_UNAUTHORIZED|Disables TLS verification via environment variable|NODE_TLS_REJECT_UNAUTHORIZED"
	"tlsv1-method|TLSv1_method|TLS 1.0 has known vulnerabilities (POODLE, BEAST)|TLSv1_method"
	"tlsv11-method|TLSv1_1_method|TLS 1.1 has known vulnerabilities|TLSv1_1_method"
	"min-version-weak|minVersion TLS 1.0/1.1|Allows weak TLS versions|minVersion.*TLSv1[^.3]"
)
