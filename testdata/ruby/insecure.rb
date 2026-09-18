# Ruby TLS anti-pattern fixtures
require "openssl"
require "net/http"
require "faraday"
require "httparty"
require "rest-client"

http = Net::HTTP.new("example.com", 443)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE

context = OpenSSL::SSL::SSLContext.new(:TLSv1)
context.ssl_version = :TLSv1_1

Faraday.get("https://example.com", ssl: { verify: false })
HTTParty.get("https://example.com", verify: false)
RestClient::Resource.new("https://example.com", verify_ssl: false)
