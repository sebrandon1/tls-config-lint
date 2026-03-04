#include <openssl/ssl.h>
#include <openssl/tls1.h>

void insecure_setup() {
    SSL_CTX *ctx = SSL_CTX_new(TLS_method());

    // CRITICAL: Disables certificate verification
    SSL_CTX_set_verify(ctx, SSL_VERIFY_NONE, NULL);

    SSL *ssl = SSL_new(ctx);
    // CRITICAL: Disables certificate verification on SSL object
    SSL_set_verify(ssl, SSL_VERIFY_NONE, NULL);
}

void weak_tls() {
    SSL_CTX *ctx = SSL_CTX_new(TLS_method());

    // HIGH: TLS 1.0
    SSL_CTX_set_min_proto_version(ctx, TLS1_VERSION);

    // HIGH: TLS 1.1
    SSL_CTX_set_min_proto_version(ctx, TLS1_1_VERSION);

    // HIGH: SSL 3.0
    SSL_CTX *ctx2 = SSL_CTX_new(SSLv3_method());

    // HIGH: TLS 1.0 method
    SSL_CTX *ctx3 = SSL_CTX_new(TLSv1_method());
}

void capped_tls() {
    SSL_CTX *ctx = SSL_CTX_new(TLS_method());
    // MEDIUM: Caps at TLS 1.2
    SSL_CTX_set_max_proto_version(ctx, TLS1_2_VERSION);
}

void strict_tls() {
    SSL_CTX *ctx = SSL_CTX_new(TLS_method());
    // INFO: Forces TLS 1.3
    SSL_CTX_set_min_proto_version(ctx, TLS1_3_VERSION);
}

void weak_ciphers() {
    SSL_CTX *ctx = SSL_CTX_new(TLS_method());
    // HIGH: Weak OpenSSL ciphers
    SSL_CTX_set_cipher_list(ctx, "DES-CBC3-SHA:RC4-SHA:NULL-SHA:EXPORT");
    // HIGH: Weak TLS 1.3 ciphers
    SSL_CTX_set_ciphersuites(ctx, "TLS_DES_CBC3_SHA:TLS_RC4_128_SHA:TLS_NULL_SHA");
}
