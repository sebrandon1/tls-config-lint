#!/usr/bin/env bash
# go.sh - Go TLS pattern definitions
# Format: "id|name|description|regex"

# shellcheck disable=SC2034  # Array is used by scanner.sh via eval
GO_PATTERNS=(
	"insecure-skip-verify|InsecureSkipVerify: true|Disables TLS certificate verification (MITM vulnerability)|InsecureSkipVerify[[:space:]]*:[[:space:]]*true"
	"min-version-tls10|MinVersion TLS 1.0|TLS 1.0 has known vulnerabilities (POODLE, BEAST)|MinVersion[[:space:]]*[:=][[:space:]]*.*VersionTLS10"
	"min-version-tls11|MinVersion TLS 1.1|TLS 1.1 has known vulnerabilities|MinVersion[[:space:]]*[:=][[:space:]]*.*VersionTLS11"
	"max-version-tls10|MaxVersion TLS 1.0|Limits connections to weak TLS 1.0|MaxVersion[[:space:]]*[:=][[:space:]]*.*VersionTLS10"
	"max-version-tls11|MaxVersion TLS 1.1|Limits connections to weak TLS 1.1|MaxVersion[[:space:]]*[:=][[:space:]]*.*VersionTLS11"
	"hardcoded-tls-config|Hardcoded tls.Config|Hardcoded TLS config not using centralized tlsSecurityProfile|tls\.Config[[:space:]]*\{"
)
