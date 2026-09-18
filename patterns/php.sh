#!/usr/bin/env bash
# php.sh - PHP TLS pattern definitions
# Format: "id|severity|name|description|regex"

# shellcheck disable=SC2034  # Array is used by scanner.sh via eval
PHP_PATTERNS=(
	"curl-ssl-verifypeer-off|CRITICAL|cURL certificate verification disabled|Disables peer certificate verification in cURL|CURLOPT_SSL_VERIFYPEER[[:space:]]*,[[:space:]]*(false|0)"
	"curl-ssl-verifyhost-off|CRITICAL|cURL hostname verification disabled|Disables hostname verification in cURL|CURLOPT_SSL_VERIFYHOST[[:space:]]*,[[:space:]]*(false|0)"
	"php-stream-verify-peer-false|CRITICAL|PHP stream peer verification disabled|Disables peer certificate verification in a PHP stream context|['\"]?verify_peer['\"]?[[:space:]]*=>[[:space:]]*(false|0)"
	"php-stream-verify-name-false|CRITICAL|PHP stream hostname verification disabled|Disables hostname verification in a PHP stream context|['\"]?verify_peer_name['\"]?[[:space:]]*=>[[:space:]]*(false|0)"
	"guzzle-verify-false|CRITICAL|Guzzle verification disabled|Disables certificate verification in a Guzzle client|Guzzle.*['\"]?verify['\"]?[[:space:]]*=>[[:space:]]*false|['\"]?verify['\"]?[[:space:]]*=>[[:space:]]*false.*Guzzle"
)
