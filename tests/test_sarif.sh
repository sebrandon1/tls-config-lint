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
FINDINGS+=("insecure-skip-verify|CRITICAL|InsecureSkipVerify|Disables certificate verification|main.go|42|InsecureSkipVerify: true")
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
FINDINGS+=("insecure-skip-verify|CRITICAL|InsecureSkipVerify|Disables cert verification|main.go|10|code1")
FINDINGS+=("insecure-skip-verify|CRITICAL|InsecureSkipVerify|Disables cert verification|handler.go|25|code2")
FINDINGS+=("weak-tls-version|HIGH|WeakTLS|Uses TLS 1.0|server.go|50|code3")
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")

assert_equals "Deduplication: 2 unique rules from 3 findings" "2" "$(echo "$sarif_json" | jq '.runs[0].tool.driver.rules | length')"
assert_equals "Deduplication: all 3 results present" "3" "$(echo "$sarif_json" | jq '.runs[0].results | length')"

# Test: Severity mapping to SARIF levels
FINDINGS=()
FINDINGS+=("p-critical|CRITICAL|C|Desc|f.go|1|c")
FINDINGS+=("p-high|HIGH|H|Desc|f.go|2|c")
FINDINGS+=("p-medium|MEDIUM|M|Desc|f.go|3|c")
FINDINGS+=("p-info|INFO|I|Desc|f.go|4|c")
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

# Test: SARIF schema reference
assert_contains "SARIF has schema reference" "sarif-schema-2.1.0" "$(echo "$sarif_json" | jq -r '.["$schema"]')"

# Test: Result snippet is preserved
FINDINGS=()
FINDINGS+=("test-pattern|HIGH|Test|Desc|app.go|99|tls.Config{MinVersion: 0}")
generate_sarif "$sarif_out" 2>/dev/null
sarif_json=$(cat "$sarif_out")
assert_equals "Snippet is preserved" "tls.Config{MinVersion: 0}" "$(echo "$sarif_json" | jq -r '.runs[0].results[0].locations[0].physicalLocation.region.snippet.text')"
