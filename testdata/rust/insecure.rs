use reqwest::ClientBuilder;
use native_tls::{TlsConnector, Protocol};
use openssl::ssl::{SslConnector, SslMethod, SslVerifyMode, SslVersion};
use rustls::client::ServerCertVerifier;

// CRITICAL: Disable certificate verification (reqwest)
fn disable_cert_verify() -> reqwest::Client {
    ClientBuilder::new()
        .danger_accept_invalid_certs(true)
        .build()
        .unwrap()
}

// CRITICAL: Disable hostname verification (reqwest)
fn disable_hostname_verify() -> reqwest::Client {
    ClientBuilder::new()
        .danger_accept_invalid_hostnames(true)
        .build()
        .unwrap()
}

// CRITICAL: Disable hostname verification (reqwest tls variant)
fn disable_tls_hostname_verify() -> reqwest::Client {
    ClientBuilder::new()
        .tls_danger_accept_invalid_certs(true)
        .build()
        .unwrap()
}

// CRITICAL: Disable hostname verification (reqwest tls variant)
fn disable_tls_hostname_verify2() -> reqwest::Client {
    ClientBuilder::new()
        .tls_danger_accept_invalid_hostnames(true)
        .build()
        .unwrap()
}

// CRITICAL: OpenSSL verify none
fn openssl_no_verify() {
    let mut ctx = SslConnector::builder(SslMethod::tls()).unwrap();
    ctx.set_verify(SslVerifyMode::NONE);
}

// CRITICAL: Custom dangerous ServerCertVerifier (rustls)
struct NoVerifier;
impl ServerCertVerifier for NoVerifier {
    fn verify_server_cert(&self, _: &rustls::Certificate) -> Result<ServerCertVerified, rustls::Error> {
        Ok(ServerCertVerified::assertion())
    }
}

// CRITICAL: Disable hostname verification (openssl)
fn openssl_no_hostname() {
    let mut connector = SslConnector::builder(SslMethod::tls()).unwrap();
    connector.set_verify_hostname(false);
}

// HIGH: TLS 1.0 protocol (native-tls)
fn use_tls10() -> TlsConnector {
    TlsConnector::builder()
        .min_protocol_version(Some(Protocol::Tlsv10))
        .build()
        .unwrap()
}

// HIGH: TLS 1.1 protocol (native-tls)
fn use_tls11() -> TlsConnector {
    TlsConnector::builder()
        .min_protocol_version(Some(Protocol::Tlsv11))
        .build()
        .unwrap()
}

// HIGH: SSL 3.0 (openssl)
fn use_ssl3() {
    let mut ctx = SslConnector::builder(SslMethod::tls()).unwrap();
    ctx.set_min_proto_version(Some(SslVersion::SSL3)).unwrap();
}

// HIGH: Weak ciphers (openssl)
fn weak_ciphers() {
    let mut ctx = SslConnector::builder(SslMethod::tls()).unwrap();
    ctx.set_cipher_list("DES-CBC3-SHA:RC4-SHA:NULL-SHA:EXPORT").unwrap();
}

// HIGH: Weak minimum TLS version
fn weak_min_version() {
    let config = rustls::ClientConfig::builder()
        .with_min_tls_version(TLS_1_0)
        .with_safe_defaults();
}

// HIGH: Weak minimum TLS version (variant)
fn weak_min_version2() {
    let config = rustls::ClientConfig::builder()
        .with_min_tls_version(TLS_1_1)
        .with_safe_defaults();
}

// MEDIUM: Max TLS version capped at 1.2
fn cap_tls12() {
    let config = rustls::ClientConfig::builder()
        .with_max_tls_version(TLS_1_2)
        .with_safe_defaults();
}

// MEDIUM: Max TLS version capped at 1.2 (native-tls variant)
fn cap_tls12_native() -> TlsConnector {
    TlsConnector::builder()
        .max_protocol_version(Some(Protocol::Tlsv12))
        .build()
        .unwrap()
}

// MEDIUM: Custom cipher list (openssl)
fn custom_ciphers() {
    let mut ctx = SslConnector::builder(SslMethod::tls()).unwrap();
    ctx.set_ciphersuites("TLS_AES_256_GCM_SHA384").unwrap();
}

// INFO: Forces TLS 1.3 only
fn force_tls13() {
    let config = rustls::ClientConfig::builder()
        .with_min_tls_version(TLS_1_3)
        .with_safe_defaults();
}

// INFO: PQC/ML-KEM post-quantum cryptography
fn post_quantum_setup() {
    let config = rustls::ClientConfig::builder()
        .with_protocol_versions(&[&rustls_post_quantum::X25519MLKEM768])
        .with_safe_defaults();
}
