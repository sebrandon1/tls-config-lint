#!/usr/bin/env bash
# nodejs.sh - Node.js/TypeScript TLS pattern definitions
# Format: "id|severity|name|description|regex"

# shellcheck disable=SC2034  # Array is used by scanner.sh via eval
NODEJS_PATTERNS=(
	"reject-unauthorized-false|CRITICAL|rejectUnauthorized: false|Disables TLS certificate verification (MITM vulnerability)|rejectUnauthorized[[:space:]]*:[[:space:]]*false"
	"node-tls-reject-unauthorized|CRITICAL|NODE_TLS_REJECT_UNAUTHORIZED|Disables TLS verification via environment variable|NODE_TLS_REJECT_UNAUTHORIZED"
	"tlsv1-method|HIGH|TLSv1_method|TLS 1.0 has known vulnerabilities (POODLE, BEAST)|TLSv1_method"
	"tlsv11-method|HIGH|TLSv1_1_method|TLS 1.1 has known vulnerabilities|TLSv1_1_method"
	"min-version-weak|HIGH|minVersion TLS 1.0/1.1|Allows weak TLS versions|minVersion.*TLSv1[^.3]"
	"max-version-tlsv12|MEDIUM|maxVersion TLSv1.2|Caps maximum TLS version at 1.2, preventing TLS 1.3|maxVersion.*TLSv1\.2"
	"min-version-tlsv13|INFO|minVersion TLSv1.3|Forces TLS 1.3 (may break older clients)|minVersion.*TLSv1\.3"
)
