#!/usr/bin/env bash
# test_summary.sh - Summary generator tests

# Source library modules
source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/lib/scanner.sh"
source "$ROOT_DIR/lib/summary.sh"

echo "  --- Summary Tests ---"

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
