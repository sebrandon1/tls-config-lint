#!/usr/bin/env bash
# ruby.sh - Ruby TLS pattern definitions
# Format: "id|severity|name|description|regex"

# shellcheck disable=SC2034  # Array is used by scanner.sh via eval
RUBY_PATTERNS=(
	"net-http-verify-none|CRITICAL|Net::HTTP VERIFY_NONE|Disables certificate verification in Net::HTTP (MITM vulnerability)|verify_mode[[:space:]]*=[[:space:]]*OpenSSL::SSL::VERIFY_NONE"
	"ruby-openssl-weak-protocol|HIGH|Weak OpenSSL protocol|Uses SSLv3, TLS 1.0, or TLS 1.1 in Ruby OpenSSL configuration|OpenSSL::SSL::SSLContext.*(SSLv3|TLSv1|TLSv1_1)|ssl_version[[:space:]]*=[[:space:]]*.*(SSLv3|TLSv1|TLSv1_1)|min_version[[:space:]]*=[[:space:]]*.*(TLS1[^_2-9]|TLS1_1|SSL3)"
	"faraday-verify-false|CRITICAL|Faraday verification disabled|Disables TLS certificate verification in Faraday|Faraday.*verify[[:space:]]*:[[:space:]]*false|verify[[:space:]]*:[[:space:]]*false.*Faraday"
	"httparty-verify-false|CRITICAL|HTTParty verification disabled|Disables TLS certificate verification in HTTParty|HTTParty.*verify[[:space:]]*:[[:space:]]*false|verify[[:space:]]*:[[:space:]]*false.*HTTParty"
	"rest-client-verify-false|CRITICAL|RestClient verification disabled|Disables TLS certificate verification in RestClient|RestClient.*verify_ssl[[:space:]]*:[[:space:]]*false|verify_ssl[[:space:]]*:[[:space:]]*false.*RestClient"
)
