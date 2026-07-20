#!/usr/bin/env bash
# test_summary.sh - Summary generator tests

# Force GitHub Actions mode for existing tests
GITHUB_ACTIONS=true

# Source library modules
source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/lib/scanner.sh"
source "$ROOT_DIR/lib/summary.sh"

echo "  --- Summary Tests (GitHub Actions mode) ---"

# Ensure summary goes to stdout, not GITHUB_STEP_SUMMARY
unset GITHUB_STEP_SUMMARY

# Test: Zero findings summary
FINDINGS=()
# shellcheck disable=SC2034  # Used by generate_summary via get_findings_count
CRITICAL_COUNT=0
# shellcheck disable=SC2034  # Used by generate_summary via get_findings_count
HIGH_COUNT=0
# shellcheck disable=SC2034  # Used by generate_summary via get_findings_count
MEDIUM_COUNT=0
# shellcheck disable=SC2034  # Used by generate_summary via get_findings_count
INFO_COUNT=0

output=$(generate_summary "high")
assert_contains "Zero findings shows no-issues message" "No TLS configuration issues found" "$output"

# Test: Summary with findings
FINDINGS=()
FINDINGS+=("test-critical|CRITICAL|Test Critical|Critical desc|test.go|10|code")
FINDINGS+=("test-medium|MEDIUM|Test Medium|Medium desc|test.py|20|code")
# shellcheck disable=SC2034  # Used by generate_summary
CRITICAL_COUNT=1
# shellcheck disable=SC2034  # Used by generate_summary
HIGH_COUNT=0
# shellcheck disable=SC2034  # Used by generate_summary
MEDIUM_COUNT=1
# shellcheck disable=SC2034  # Used by generate_summary
INFO_COUNT=0

output=$(generate_summary "high")
assert_contains "Summary contains severity table" "Critical" "$output"
assert_contains "Summary contains total count" "Total findings" "$output"
assert_contains "Summary shows threshold" "high" "$output"
assert_contains "Summary contains findings table" "test.go" "$output"
assert_contains "Summary contains file reference" "test.py" "$output"

# --- CLI mode tests ---
echo "  --- Summary Tests (CLI mode) ---"

unset GITHUB_ACTIONS
source "$ROOT_DIR/lib/utils.sh"

# Test: CLI zero findings
FINDINGS=()
# shellcheck disable=SC2034
CRITICAL_COUNT=0
# shellcheck disable=SC2034
HIGH_COUNT=0
# shellcheck disable=SC2034
MEDIUM_COUNT=0
# shellcheck disable=SC2034
INFO_COUNT=0

output=$(generate_summary "high")
assert_contains "CLI zero findings shows no-issues message" "No TLS configuration issues found" "$output"

# Test: CLI summary with findings
FINDINGS=()
FINDINGS+=("test-critical|CRITICAL|Test Critical|Critical desc|test.go|10|code")
FINDINGS+=("test-medium|MEDIUM|Test Medium|Medium desc|test.py|20|code")
# shellcheck disable=SC2034
CRITICAL_COUNT=1
# shellcheck disable=SC2034
HIGH_COUNT=0
# shellcheck disable=SC2034
MEDIUM_COUNT=1
# shellcheck disable=SC2034
INFO_COUNT=0

output=$(generate_summary "high")
assert_contains "CLI summary shows Critical count" "Critical" "$output"
assert_contains "CLI summary shows Medium count" "Medium" "$output"
assert_contains "CLI summary shows total" "Total" "$output"
assert_contains "CLI summary shows threshold" "high" "$output"

# Test: CLI summary shows config file when set
# shellcheck disable=SC2034  # Used by generate_summary
CONFIG_FILE_USED=".tls-config-lint.yml"
output=$(generate_summary "high")
assert_contains "CLI summary shows config file" "Config: .tls-config-lint.yml" "$output"
unset CONFIG_FILE_USED

# Test: CLI summary shows multi-language breakdown
FINDINGS=()
FINDINGS+=("test-critical|CRITICAL|Test Critical|Critical desc|test.go|10|code")
FINDINGS+=("test-medium|MEDIUM|Test Medium|Medium desc|test.py|20|code")
FINDINGS+=("test-info|INFO|Test Info|Info desc|test.js|30|code")
# shellcheck disable=SC2034
CRITICAL_COUNT=1
# shellcheck disable=SC2034
HIGH_COUNT=0
# shellcheck disable=SC2034
MEDIUM_COUNT=1
# shellcheck disable=SC2034
INFO_COUNT=1

output=$(generate_summary "high")
assert_contains "CLI summary shows multi-language breakdown" "By language:" "$output"

# CLI should not produce markdown syntax
if echo "$output" | grep -q ":red_circle:"; then
	assert_equals "CLI mode has no markdown emoji" "true" "false"
else
	assert_equals "CLI mode has no markdown emoji" "true" "true"
fi

if echo "$output" | grep -q "|-------"; then
	assert_equals "CLI mode has no markdown table borders" "true" "false"
else
	assert_equals "CLI mode has no markdown table borders" "true" "true"
fi

# Restore GitHub Actions mode for subsequent test files
# shellcheck disable=SC2034  # Used by utils.sh on re-source
GITHUB_ACTIONS=true
source "$ROOT_DIR/lib/utils.sh"
