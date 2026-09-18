#!/usr/bin/env bash
# test_baseline.sh - SARIF baseline comparison tests

source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/lib/scanner.sh"
source "$ROOT_DIR/lib/baseline.sh"

echo "  --- Baseline Tests ---"

baseline_file=$(mktemp)
cat >"$baseline_file" <<'EOF'
{
  "version": "2.1.0",
  "runs": [{
    "tool": {"driver": {"name": "tls-config-lint"}},
    "results": [
      {
        "ruleId": "verify-false",
        "locations": [{"physicalLocation": {"artifactLocation": {"uri": "src/client.py"}, "region": {"startLine": 10}}}]
      },
      {
        "ruleId": "verify-false",
        "locations": [{"physicalLocation": {"artifactLocation": {"uri": "src/client.py"}, "region": {"startLine": 10}}}]
      },
      {
        "ruleId": "other-rule",
        "locations": [{"physicalLocation": {"artifactLocation": {"uri": "src/client.py"}, "region": {"startLine": 20}}}]
      }
    ]
  }]
}
EOF

load_baseline "$baseline_file" "$ROOT_DIR"
assert_equals "Loads SARIF baseline entries" "3" "${#BASELINE_ENTRIES[@]}"

assert_equals "Exact baseline finding matches" "true" "$(baseline_has_finding verify-false src/client.py 10 && echo true || echo false)"
assert_equals "Nearby line matches baseline" "true" "$(baseline_has_finding verify-false src/client.py 13 && echo true || echo false)"
assert_equals "Distant line does not match baseline" "false" "$(baseline_has_finding verify-false src/client.py 14 && echo true || echo false)"
assert_equals "Different pattern does not match baseline" "false" "$(baseline_has_finding new-rule src/client.py 20 && echo true || echo false)"

FINDINGS=(
	"verify-false|critical|Verification disabled|Use certificate verification|src/client.py|13|verify=False|1"
	"verify-false|critical|Verification disabled|Use certificate verification|src/client.py|30|verify=False|1"
	"new-rule|high|New rule|New finding|src/client.py|20|bad|1"
)
# shellcheck disable=SC2034 # Consumed by filter_baseline_findings in baseline.sh
FINDING_REGEXES=("verify=False" "verify=False" "bad")
# shellcheck disable=SC2034 # Consumed by filter_baseline_findings in baseline.sh
CRITICAL_COUNT=2
# shellcheck disable=SC2034 # Consumed by filter_baseline_findings in baseline.sh
HIGH_COUNT=1
# shellcheck disable=SC2034 # Consumed by filter_baseline_findings in baseline.sh
MEDIUM_COUNT=0
# shellcheck disable=SC2034 # Consumed by filter_baseline_findings in baseline.sh
INFO_COUNT=0
filter_baseline_findings

assert_equals "Baseline filter suppresses nearby existing finding" "2" "${#FINDINGS[@]}"
assert_equals "Baseline filter updates critical count" "1" "$CRITICAL_COUNT"
assert_equals "Baseline filter preserves new findings" "true" "$(printf '%s\n' "${FINDINGS[@]}" | grep -q 'src/client.py|30|' && echo true || echo false)"
assert_equals "Baseline filter preserves different rule at same line" "true" "$(printf '%s\n' "${FINDINGS[@]}" | grep -q 'new-rule|' && echo true || echo false)"
assert_equals "Baseline suppression count is tracked" "1" "$BASELINE_SUPPRESSED_COUNT"

empty_baseline=$(mktemp)
cat >"$empty_baseline" <<'EOF'
{"version":"2.1.0","runs":[{"tool":{"driver":{"name":"tls-config-lint"}},"results":[]}]}
EOF
load_baseline "$empty_baseline" "$ROOT_DIR"
assert_equals "Empty baseline loads successfully" "0" "${#BASELINE_ENTRIES[@]}"

invalid_baseline=$(mktemp)
echo '{"version":"1.0"}' >"$invalid_baseline"
if load_baseline "$invalid_baseline" "$ROOT_DIR"; then
	assert_equals "Malformed baseline is rejected" "false" "true"
else
	assert_equals "Malformed baseline is rejected" "true" "true"
fi

rm -f "$baseline_file" "$empty_baseline" "$invalid_baseline"
