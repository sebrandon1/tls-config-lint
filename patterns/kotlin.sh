#!/usr/bin/env bash
# kotlin.sh - Kotlin TLS pattern definitions
# Format: "id|severity|name|description|regex"

# shellcheck disable=SC2034  # Array is used by scanner.sh via eval
KOTLIN_PATTERNS=(
	"kotlin-sslcontext-weak|HIGH|Weak Kotlin SSLContext protocol|Uses SSLv3, TLS 1.0, or TLS 1.1 in Kotlin SSLContext|SSLContext[.]getInstance[[:space:]]*[(].*(TLSv1[^.]?($|\"|')|TLSv1[.]1|SSLv3)"
	"ktor-trust-manager-bypass|CRITICAL|Ktor trust manager bypass|Configures Ktor with a null or trust-all manager|trustManager.*(null|TrustAll|Insecure|X509TrustManager)"
	"okhttp-hostname-verifier-bypass|CRITICAL|OkHttp hostname verification bypass|Configures OkHttp with an always-true hostname verifier|hostnameVerifier.*(true|->[[:space:]]*true)"
	"okhttp-ssl-socket-factory-bypass|CRITICAL|OkHttp SSL socket factory bypass|Configures OkHttp with an insecure SSL socket factory|sslSocketFactory[[:space:]]*[(].*(TrustAll|Insecure|X509TrustManager)"
	"kotlin-trust-manager-all|CRITICAL|Kotlin trust-all manager|Defines a trust manager that accepts every server certificate|X509TrustManager.*(checkServerTrusted|checkClientTrusted)|checkServerTrusted[[:space:]]*[(].*\)[[:space:]]*[{][[:space:]]*[}]"
)
