#include <openssl/ssl.h>
#include <openssl/tls1.h>

void insecure_c_setup() {
    SSL_CTX *ctx = SSL_CTX_new(TLS_method());

    /* CRITICAL: Disables certificate verification */
    SSL_CTX_set_verify(ctx, SSL_VERIFY_NONE, NULL);

    SSL *ssl = SSL_new(ctx);
    /* CRITICAL: Disables certificate verification on SSL object */
    SSL_set_verify(ssl, SSL_VERIFY_NONE, NULL);
}

void weak_c_tls() {
    SSL_CTX *ctx = SSL_CTX_new(TLS_method());

    /* HIGH: TLS 1.0 */
    SSL_CTX_set_min_proto_version(ctx, TLS1_VERSION);

    /* HIGH: SSL 3.0 */
    SSL_CTX *ctx2 = SSL_CTX_new(SSLv3_method());
}

void insecure_c_curl() {
    CURL *curl = curl_easy_init();
    /* CRITICAL: Disables peer certificate verification */
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0);
}

void weak_c_ciphers() {
    SSL_CTX *ctx = SSL_CTX_new(TLS_method());
    /* HIGH: Weak OpenSSL ciphers */
    SSL_CTX_set_cipher_list(ctx, "DES-CBC3-SHA:RC4-SHA:NULL-SHA:EXPORT");
}
