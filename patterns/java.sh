#!/usr/bin/env bash
# java.sh - Java TLS pattern definitions
# Format: "id|severity|name|description|regex"

# shellcheck disable=SC2034  # Array is used by scanner.sh via eval
JAVA_PATTERNS=(
	"allow-all-hostname-verifier|CRITICAL|ALLOW_ALL HostnameVerifier|Disables hostname verification (MITM vulnerability)|setHostnameVerifier.*ALLOW_ALL|HostnameVerifier.*return[[:space:]]+true"
	"trust-all-certs|CRITICAL|TrustAllCerts / permissive TrustManager|Custom TrustManager that does not verify certificates (MITM vulnerability)|TrustAllCerts|X509TrustManager[^{]*\{[^}]*checkServerTrusted"
	"custom-ssl-socket-factory|CRITICAL|setSSLSocketFactory bypass|Sets custom SSLSocketFactory that may bypass verification|setSSLSocketFactory"
	"unversioned-ssl-context|HIGH|SSLContext.getInstance TLS unversioned|SSLContext.getInstance with bare TLS defaults to oldest supported version|SSLContext\.getInstance\(\"TLS\"\)"
	"sslcontext-tlsv1|HIGH|SSLContext.getInstance TLSv1|TLS 1.0 has known vulnerabilities (POODLE, BEAST)|SSLContext\.getInstance\(\"TLSv1\"\)"
	"sslcontext-tlsv11|HIGH|SSLContext.getInstance TLSv1.1|TLS 1.1 has known vulnerabilities|SSLContext\.getInstance\(\"TLSv1\.1\"\)"
	"enabled-weak-protocols|MEDIUM|setEnabledProtocols weak TLS|Enables deprecated TLS 1.0 or 1.1 protocols|setEnabledProtocols.*TLSv1[^.2-9]|setEnabledProtocols.*TLSv1\.1"
	"sslcontext-tlsv13|INFO|SSLContext.getInstance TLSv1.3|Forces TLS 1.3 only (may break older clients)|SSLContext\.getInstance\(\"TLSv1\.3\"\)"
)
