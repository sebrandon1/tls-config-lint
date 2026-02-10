#!/usr/bin/env bash
# go.sh - Go TLS pattern definitions
# Format: "id|severity|name|description|regex"

# shellcheck disable=SC2034  # Array is used by scanner.sh via eval
GO_PATTERNS=(
	"insecure-skip-verify|CRITICAL|InsecureSkipVerify: true|Disables TLS certificate verification (MITM vulnerability)|InsecureSkipVerify[[:space:]]*:[[:space:]]*true"
	"min-version-tls10|HIGH|MinVersion TLS 1.0|TLS 1.0 has known vulnerabilities (POODLE, BEAST)|MinVersion[[:space:]]*[:=][[:space:]]*.*VersionTLS10"
	"min-version-tls11|HIGH|MinVersion TLS 1.1|TLS 1.1 has known vulnerabilities|MinVersion[[:space:]]*[:=][[:space:]]*.*VersionTLS11"
	"max-version-tls10|HIGH|MaxVersion TLS 1.0|Limits connections to weak TLS 1.0|MaxVersion[[:space:]]*[:=][[:space:]]*.*VersionTLS10"
	"max-version-tls11|HIGH|MaxVersion TLS 1.1|Limits connections to weak TLS 1.1|MaxVersion[[:space:]]*[:=][[:space:]]*.*VersionTLS11"
	"max-version-tls12|MEDIUM|MaxVersion TLS 1.2|Prevents TLS 1.3 negotiation|MaxVersion[[:space:]]*[:=][[:space:]]*.*VersionTLS12"
	"min-version-tls13|INFO|MinVersion TLS 1.3|Forces TLS 1.3 (may break older clients)|MinVersion[[:space:]]*[:=][[:space:]]*.*VersionTLS13"
	"prefer-server-cipher-suites|INFO|PreferServerCipherSuites|Deprecated in Go 1.17+ (ignored)|PreferServerCipherSuites[[:space:]]*:[[:space:]]*true"
	"curve-preferences|INFO|CurvePreferences|Explicit curve configuration (PQC readiness indicator)|CurvePreferences[[:space:]]*[:=]"
	"hardcoded-tls-config|INFO|Hardcoded tls.Config|Hardcoded TLS config (review for API server TLS profile adherence)|tls\.Config[[:space:]]*\{"
	"pqc-ml-kem|INFO|PQC/ML-KEM patterns|Post-Quantum Cryptography adoption (ML-KEM)|(X25519MLKEM|MLKEM768|mlkem768|crypto/mlkem|NewDecapsulationKey|NewEncapsulationKey)"
)
