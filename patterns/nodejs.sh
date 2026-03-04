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
	"weak-cipher-config|HIGH|Weak cipher configuration|Weak or insecure ciphers in TLS options|ciphers.*(DES|RC4|NULL|EXPORT)"
	"honor-cipher-order-false|MEDIUM|honorCipherOrder disabled|Server does not enforce cipher preference order|honorCipherOrder.*false"
	"axios-defaults-httpsagent|MEDIUM|axios defaults httpsAgent|Global default HTTPS agent override (review TLS settings)|axios\.defaults\.httpsAgent"
	"strict-ssl-false|CRITICAL|strictSSL: false|Disables TLS certificate verification in request/request-promise|strictSSL[[:space:]]*:[[:space:]]*false"
	"secure-protocol-weak|HIGH|Weak secureProtocol|Weak TLS protocol version in HTTPS options|secureProtocol[[:space:]]*:[[:space:]]*['\"]TLSv1[^.3]"
)
