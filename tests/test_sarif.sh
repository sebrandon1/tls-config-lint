#!/usr/bin/env bash
# test_sarif.sh - SARIF generator tests

# Source library modules
source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/lib/scanner.sh"
source "$ROOT_DIR/lib/sarif.sh"

echo "  --- SARIF Tests ---"

sarif_out=$(mktemp)
trap 'rm -f "$sarif_out"' RETURN

# Test: Single finding produces correct rule and result
FINDINGS=()
FINDINGS+=("insecure-skip-verify|CRITICAL|InsecureSkipVerify|Disables certificate verification|main.go|42|InsecureSkipVerify: true|5")
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")

assert_equals "Single finding has one rule" "1" "$(echo "$sarif_json" | jq '.runs[0].tool.driver.rules | length')"
assert_equals "Single finding has one result" "1" "$(echo "$sarif_json" | jq '.runs[0].results | length')"
assert_equals "Rule ID matches pattern ID" "insecure-skip-verify" "$(echo "$sarif_json" | jq -r '.runs[0].tool.driver.rules[0].id')"
assert_equals "Result ruleId matches" "insecure-skip-verify" "$(echo "$sarif_json" | jq -r '.runs[0].results[0].ruleId')"
assert_equals "Result file matches" "main.go" "$(echo "$sarif_json" | jq -r '.runs[0].results[0].locations[0].physicalLocation.artifactLocation.uri')"
assert_equals "Result line matches" "42" "$(echo "$sarif_json" | jq '.runs[0].results[0].locations[0].physicalLocation.region.startLine')"

# Test: Duplicate pattern IDs produce deduplicated rules
FINDINGS=()
FINDINGS+=("insecure-skip-verify|CRITICAL|InsecureSkipVerify|Disables cert verification|main.go|10|code1|1")
FINDINGS+=("insecure-skip-verify|CRITICAL|InsecureSkipVerify|Disables cert verification|handler.go|25|code2|1")
FINDINGS+=("weak-tls-version|HIGH|WeakTLS|Uses TLS 1.0|server.go|50|code3|1")
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")

assert_equals "Deduplication: 2 unique rules from 3 findings" "2" "$(echo "$sarif_json" | jq '.runs[0].tool.driver.rules | length')"
assert_equals "Deduplication: all 3 results present" "3" "$(echo "$sarif_json" | jq '.runs[0].results | length')"

# Test: Severity mapping to SARIF levels
FINDINGS=()
FINDINGS+=("p-critical|CRITICAL|C|Desc|f.go|1|c|1")
FINDINGS+=("p-high|HIGH|H|Desc|f.go|2|c|1")
FINDINGS+=("p-medium|MEDIUM|M|Desc|f.go|3|c|1")
FINDINGS+=("p-info|INFO|I|Desc|f.go|4|c|1")
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")

assert_equals "CRITICAL maps to error" "error" "$(echo "$sarif_json" | jq -r '.runs[0].results[0].level')"
assert_equals "HIGH maps to error" "error" "$(echo "$sarif_json" | jq -r '.runs[0].results[1].level')"
assert_equals "MEDIUM maps to warning" "warning" "$(echo "$sarif_json" | jq -r '.runs[0].results[2].level')"
assert_equals "INFO maps to note" "note" "$(echo "$sarif_json" | jq -r '.runs[0].results[3].level')"

# Test: Tool metadata
assert_equals "Tool name is tls-config-lint" "tls-config-lint" "$(echo "$sarif_json" | jq -r '.runs[0].tool.driver.name')"
assert_contains "Tool has informationUri" "github.com/sebrandon1/tls-config-lint" "$(echo "$sarif_json" | jq -r '.runs[0].tool.driver.informationUri')"

# Test: Rules include helpUri
assert_contains "Rules include helpUri" "docs/patterns.md" "$(echo "$sarif_json" | jq -r '.runs[0].tool.driver.rules[0].helpUri')"
assert_contains "helpUri has pattern anchor" "#go-p-critical" "$(echo "$sarif_json" | jq -r '.runs[0].tool.driver.rules[0].helpUri')"

# Test: SARIF schema reference
assert_contains "SARIF has schema reference" "sarif-schema-2.1.0" "$(echo "$sarif_json" | jq -r '.["$schema"]')"

# Test: Result snippet is preserved
FINDINGS=()
FINDINGS+=("test-pattern|HIGH|Test|Desc|app.go|99|tls.Config{MinVersion: 0}|3")
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")
assert_equals "Snippet is preserved" "tls.Config{MinVersion: 0}" "$(echo "$sarif_json" | jq -r '.runs[0].results[0].locations[0].physicalLocation.region.snippet.text')"

# Test: partialFingerprints present on results
FINDINGS=()
FINDINGS+=("insecure-skip-verify|CRITICAL|InsecureSkipVerify|Disables cert verification|main.go|10|InsecureSkipVerify: true|5")
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")

has_fingerprint=$(echo "$sarif_json" | jq 'has("runs") and (.runs[0].results[0] | has("partialFingerprints"))')
assert_equals "Result has partialFingerprints" "true" "$has_fingerprint"
has_hash=$(echo "$sarif_json" | jq -r '.runs[0].results[0].partialFingerprints | has("primaryLocationLineHash")')
assert_equals "partialFingerprints has primaryLocationLineHash" "true" "$has_hash"

# Fingerprint is a 64-char hex string (sha256)
fp_len=$(echo "$sarif_json" | jq -r '.runs[0].results[0].partialFingerprints.primaryLocationLineHash | length')
assert_equals "Fingerprint is 64 chars (sha256)" "64" "$fp_len"

# Same content produces same fingerprint
FINDINGS=()
FINDINGS+=("insecure-skip-verify|CRITICAL|InsecureSkipVerify|Disables cert verification|main.go|10|InsecureSkipVerify: true|5")
generate_sarif "$sarif_out" 2>/dev/null
fp1=$(cat "$sarif_out" | jq -r '.runs[0].results[0].partialFingerprints.primaryLocationLineHash')
FINDINGS=()
FINDINGS+=("insecure-skip-verify|CRITICAL|InsecureSkipVerify|Disables cert verification|main.go|99|InsecureSkipVerify: true|5")
generate_sarif "$sarif_out" 2>/dev/null
fp2=$(cat "$sarif_out" | jq -r '.runs[0].results[0].partialFingerprints.primaryLocationLineHash')
assert_equals "Same content different line produces same fingerprint" "$fp1" "$fp2"

# Different content produces different fingerprint
FINDINGS=()
FINDINGS+=("insecure-skip-verify|CRITICAL|InsecureSkipVerify|Disables cert verification|main.go|10|different content here|5")
generate_sarif "$sarif_out" 2>/dev/null
fp3=$(cat "$sarif_out" | jq -r '.runs[0].results[0].partialFingerprints.primaryLocationLineHash')
if [[ "$fp1" != "$fp3" ]]; then
	assert_equals "Different content produces different fingerprint" "true" "true"
else
	assert_equals "Different content produces different fingerprint" "true" "false"
fi

# Test: startColumn and endColumn in region
FINDINGS=()
FINDINGS+=("test-col|HIGH|Test|Desc|app.go|42|some code here|5")
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")

assert_equals "startColumn matches column field" "5" "$(echo "$sarif_json" | jq '.runs[0].results[0].locations[0].physicalLocation.region.startColumn')"
assert_equals "endColumn is startCol + snippet length" "19" "$(echo "$sarif_json" | jq '.runs[0].results[0].locations[0].physicalLocation.region.endColumn')"

# Test: per-pattern tags
FINDINGS=()
FINDINGS+=("insecure-skip-verify|CRITICAL|InsecureSkipVerify|Desc|f.go|1|c|1")
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")

assert_contains "Certificate pattern has certificate-validation tag" "certificate-validation" "$(echo "$sarif_json" | jq -r '.runs[0].tool.driver.rules[0].properties.tags[]')"

FINDINGS=()
FINDINGS+=("min-version-tls10|HIGH|WeakTLS|Desc|f.go|1|c|1")
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")

assert_contains "Version pattern has protocol-version tag" "protocol-version" "$(echo "$sarif_json" | jq -r '.runs[0].tool.driver.rules[0].properties.tags[]')"

FINDINGS=()
FINDINGS+=("weak-cipher-rc4|CRITICAL|RC4|Desc|f.go|1|c|1")
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")

assert_contains "Cipher pattern has cipher-suite tag" "cipher-suite" "$(echo "$sarif_json" | jq -r '.runs[0].tool.driver.rules[0].properties.tags[]')"

FINDINGS=()
FINDINGS+=("grpc-insecure|CRITICAL|gRPC insecure|Desc|f.go|1|c|1")
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")
assert_contains "gRPC pattern has transport-security tag" "transport-security" "$(echo "$sarif_json" | jq -r '.runs[0].tool.driver.rules[0].properties.tags[]')"

FINDINGS=()
FINDINGS+=("hardcoded-tls-config|INFO|TLS Config|Desc|f.go|1|c|1")
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")
assert_contains "Fallback pattern has configuration tag" "configuration" "$(echo "$sarif_json" | jq -r '.runs[0].tool.driver.rules[0].properties.tags[]')"

# Test: Empty FINDINGS produces valid SARIF with no results
FINDINGS=()
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")
assert_equals "Empty findings produces valid SARIF" "0" "$(echo "$sarif_json" | jq '.runs[0].results | length')"
assert_equals "Empty findings has zero rules" "0" "$(echo "$sarif_json" | jq '.runs[0].tool.driver.rules | length')"
assert_equals "Empty findings has SARIF version" "2.1.0" "$(echo "$sarif_json" | jq -r '.version')"

# Test: Non-Go file produces correct helpUri lang prefix
FINDINGS=()
FINDINGS+=("verify-false|CRITICAL|VerifyFalse|Disables verification|client.py|10|verify=False|1")
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")
assert_contains "Python helpUri has python prefix" "#python-verify-false" "$(echo "$sarif_json" | jq -r '.runs[0].tool.driver.rules[0].helpUri')"

FINDINGS=()
FINDINGS+=("tls-reject-unauth|CRITICAL|RejectUnauth|Desc|server.js|10|code|1")
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")
assert_contains "Node.js helpUri has nodejs prefix" "#nodejs-tls-reject-unauth" "$(echo "$sarif_json" | jq -r '.runs[0].tool.driver.rules[0].helpUri')"

FINDINGS=()
FINDINGS+=("ssl-verifypeer|CRITICAL|VerifyPeer|Desc|client.cpp|10|code|1")
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")
assert_contains "C++ helpUri has cpp prefix" "#cpp-ssl-verifypeer" "$(echo "$sarif_json" | jq -r '.runs[0].tool.driver.rules[0].helpUri')"

FINDINGS=()
FINDINGS+=("trust-all-certs|CRITICAL|TrustAll|Desc|Main.java|10|code|1")
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")
assert_contains "Java helpUri has java prefix" "#java-trust-all-certs" "$(echo "$sarif_json" | jq -r '.runs[0].tool.driver.rules[0].helpUri')"

FINDINGS=()
FINDINGS+=("dangerous-verifier|CRITICAL|Verifier|Desc|client.rs|10|code|1")
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")
assert_contains "Rust helpUri has rust prefix" "#rust-dangerous-verifier" "$(echo "$sarif_json" | jq -r '.runs[0].tool.driver.rules[0].helpUri')"

# Test: Unknown extension has no lang prefix in helpUri
FINDINGS=()
FINDINGS+=("test-pattern|HIGH|Test|Desc|config.yml|10|code|1")
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")
assert_contains "Unknown ext helpUri has bare pattern" "#test-pattern" "$(echo "$sarif_json" | jq -r '.runs[0].tool.driver.rules[0].helpUri')"

# Test: pattern_tags for tls-profile
FINDINGS=()
FINDINGS+=("old-tls-profile|HIGH|OldProfile|Desc|f.go|1|c|1")
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")
assert_contains "tls-profile pattern has tls-profile tag" "tls-profile" "$(echo "$sarif_json" | jq -r '.runs[0].tool.driver.rules[0].properties.tags[]')"

# Test: pattern_tags for post-quantum
FINDINGS=()
FINDINGS+=("pqc-adoption|INFO|PQC|Desc|f.go|1|c|1")
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")
assert_contains "PQC pattern has post-quantum tag" "post-quantum" "$(echo "$sarif_json" | jq -r '.runs[0].tool.driver.rules[0].properties.tags[]')"

# Test: ruleIndex correctness for multiple rules
FINDINGS=()
FINDINGS+=("insecure-skip-verify|CRITICAL|ISV|Desc|f.go|1|c|1")
FINDINGS+=("min-version-tls10|HIGH|WeakTLS|Desc|f.go|2|c|1")
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")
assert_equals "First result ruleIndex is 0" "0" "$(echo "$sarif_json" | jq '.runs[0].results[0].ruleIndex')"
assert_equals "Second result ruleIndex is 1" "1" "$(echo "$sarif_json" | jq '.runs[0].results[1].ruleIndex')"

# Test: column=1 when match starts at column 1
FINDINGS=()
FINDINGS+=("test-col1|HIGH|Test|Desc|app.go|1|no leading whitespace|1")
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")
assert_equals "Column 1 for no leading whitespace" "1" "$(echo "$sarif_json" | jq '.runs[0].results[0].locations[0].physicalLocation.region.startColumn')"
