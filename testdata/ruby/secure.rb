# Secure Ruby TLS configuration should not produce Ruby-specific findings.
require "net/http"
require "openssl"

http = Net::HTTP.new("example.com", 443)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_PEER
http.min_version = OpenSSL::SSL::TLS1_2_VERSION
