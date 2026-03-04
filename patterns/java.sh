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
	"weak-cipher-suite|HIGH|Weak JSSE cipher suite|Weak or insecure cipher suites enabled|setEnabledCipherSuites.*(DES|RC4|NULL|EXPORT|anon)"
	"ssl-socket-factory-default|MEDIUM|Default SSLSocketFactory|Default SSLSocketFactory may use weak ciphers|SSLSocketFactory\.getDefault"
	"noop-hostname-verifier|CRITICAL|NoopHostnameVerifier|Apache HttpClient NoopHostnameVerifier accepts all hostnames (MITM vulnerability)|NoopHostnameVerifier"
	"trust-all-strategy|CRITICAL|TrustAllStrategy / TrustSelfSignedStrategy|Apache HttpClient trusts untrusted or self-signed certificates|TrustAllStrategy\|TrustSelfSignedStrategy"
	"okhttp-ssl-socket-factory|CRITICAL|OkHttp sslSocketFactory|OkHttp custom SSL socket factory may bypass verification|OkHttpClient.*sslSocketFactory\|\.sslSocketFactory\("
	"apache-httpclient-custom-ssl|HIGH|Apache HttpClient custom SSLContext|Custom SSLContext in Apache HttpClient (review needed)|HttpClients\.custom.*setSSLContext\|HttpClientBuilder.*setSSLContext"
	"ssl-connection-socket-factory|HIGH|SSLConnectionSocketFactory|Custom SSL connection socket factory (review needed)|SSLConnectionSocketFactory"
	"pqc-ml-kem|INFO|PQC/ML-KEM patterns|Post-Quantum Cryptography adoption (ML-KEM)|(MLKEM|ML-KEM|postQuantum|post-quantum)"
)
