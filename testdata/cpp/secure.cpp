// Properly configured TLS - should not trigger critical/high findings.
#include <openssl/ssl.h>

// Always verify peer certificates.
// Use TLS_method() for version-flexible negotiation.

SSL_CTX* create_secure_context() {
    SSL_CTX* ctx = SSL_CTX_new(TLS_method());
    SSL_CTX_set_verify(ctx, SSL_VERIFY_PEER, NULL);
    SSL_CTX_set_min_proto_version(ctx, TLS1_2_VERSION);
    SSL_CTX_set_cipher_list(ctx, "HIGH:!MD5");
    return ctx;
}

void log_status() {
    printf("Certificate verification is enabled\n");
    printf("Using modern TLS configuration\n");
}
