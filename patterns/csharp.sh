#!/usr/bin/env bash
# csharp.sh - C#/.NET TLS pattern definitions
# Format: "id|severity|name|description|regex"

# shellcheck disable=SC2034  # Array is used by scanner.sh via eval
CSHARP_PATTERNS=(
	"servicepointmanager-callback-true|CRITICAL|ServicePointManager validation bypass|Accepts every server certificate through ServicePointManager|ServerCertificateValidationCallback[[:space:]]*=.*(true|=>[[:space:]]*true)"
	"httpclienthandler-callback-true|CRITICAL|HttpClientHandler validation bypass|Accepts every server certificate through HttpClientHandler|ServerCertificateCustomValidationCallback[[:space:]]*=.*(true|=>[[:space:]]*true)"
	"sslstream-weak-protocol|HIGH|SslStream weak protocol|Enables TLS 1.0 or TLS 1.1 in SslStream|SslProtocols.*(Tls11|Tls[^0-9])"
	"securityprotocol-weak|HIGH|Weak SecurityProtocolType|Enables TLS 1.0 or TLS 1.1 through ServicePointManager|SecurityProtocolType[.](Tls11|Tls[^0-9])"
)
