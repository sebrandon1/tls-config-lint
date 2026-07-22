#!/usr/bin/env bash
# test_summary.sh - Summary generator tests
# shellcheck disable=SC2218  # Functions defined via source in run_tests.sh

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

# --- GITHUB_STEP_SUMMARY file write test ---
echo "  --- Summary File Write Tests ---"

# shellcheck disable=SC2034  # Used by utils.sh on re-source
GITHUB_ACTIONS=true
source "$ROOT_DIR/lib/utils.sh"

FINDINGS=()
FINDINGS+=("test-critical|CRITICAL|Test Critical|Critical desc|test.go|10|code")
# shellcheck disable=SC2034
CRITICAL_COUNT=1
# shellcheck disable=SC2034
HIGH_COUNT=0
# shellcheck disable=SC2034
MEDIUM_COUNT=0
# shellcheck disable=SC2034
INFO_COUNT=0

summary_tmpfile=$(mktemp)
# shellcheck disable=SC2034
GITHUB_STEP_SUMMARY="$summary_tmpfile"
generate_summary "high" >/dev/null
summary_file_content=$(cat "$summary_tmpfile")
assert_contains "GITHUB_STEP_SUMMARY receives summary content" "Critical" "$summary_file_content"
assert_contains "GITHUB_STEP_SUMMARY has findings" "test.go" "$summary_file_content"
rm -f "$summary_tmpfile"
unset GITHUB_STEP_SUMMARY

# --- Pipe character escaping test ---
FINDINGS=()
FINDINGS+=("test-pipe|HIGH|Test|Description with | pipe char|test.go|10|code")
# shellcheck disable=SC2034
CRITICAL_COUNT=0
# shellcheck disable=SC2034
HIGH_COUNT=1
# shellcheck disable=SC2034
MEDIUM_COUNT=0
# shellcheck disable=SC2034
INFO_COUNT=0

unset GITHUB_STEP_SUMMARY
output=$(generate_summary "high")
# The pipe in "Description with | pipe char" should be escaped as \| in markdown
assert_contains "GHA summary escapes pipes in description" 'pipe char' "$output"

# --- Exclusion Audit Tests (GHA mode) ---
echo "  --- Exclusion Audit Tests ---"

source "$ROOT_DIR/lib/utils.sh"

FINDINGS=()
FINDINGS+=("test-high|HIGH|Test High|High finding|test.go|10|code")
# shellcheck disable=SC2034
CRITICAL_COUNT=0
# shellcheck disable=SC2034
HIGH_COUNT=1
# shellcheck disable=SC2034
MEDIUM_COUNT=0
# shellcheck disable=SC2034
INFO_COUNT=0

# Simulate exclusion audit state
# shellcheck disable=SC2034
EXCLUDE_PATTERNS="insecure-skip-verify,verify-false"
# shellcheck disable=SC2034
EXCLUDED_PATTERNS_USED="insecure-skip-verify"
# shellcheck disable=SC2034
EXCEPTIONS="min-version-tls10:legacy/"
# shellcheck disable=SC2034
EXCEPTIONS_USED=""
# shellcheck disable=SC2034
INLINE_SUPPRESSION_COUNT=2

unset GITHUB_STEP_SUMMARY
output=$(generate_summary "high")

assert_contains "GHA audit shows used pattern as suppressed" "Suppressed" "$output"
assert_contains "GHA audit shows unused pattern as warning" "Unused" "$output"
assert_contains "GHA audit shows insecure-skip-verify" "insecure-skip-verify" "$output"
assert_contains "GHA audit shows verify-false" "verify-false" "$output"
assert_contains "GHA audit shows unused exception" "min-version-tls10:legacy/" "$output"
assert_contains "GHA audit shows inline count" "2 finding(s) suppressed" "$output"

# Test: No audit section when no exclusions configured
# shellcheck disable=SC2034
EXCLUDE_PATTERNS=""
# shellcheck disable=SC2034
EXCLUDED_PATTERNS_USED=""
# shellcheck disable=SC2034
EXCEPTIONS=""
# shellcheck disable=SC2034
EXCEPTIONS_USED=""
# shellcheck disable=SC2034
INLINE_SUPPRESSION_COUNT=0

output=$(generate_summary "high")
if echo "$output" | grep -q "Exclusion Audit"; then
	assert_equals "GHA no audit when no exclusions" "true" "false"
else
	assert_equals "GHA no audit when no exclusions" "true" "true"
fi

# Test: CLI mode exclusion audit
unset GITHUB_ACTIONS
source "$ROOT_DIR/lib/utils.sh"

FINDINGS=()
FINDINGS+=("test-high|HIGH|Test High|High finding|test.go|10|code")
# shellcheck disable=SC2034
CRITICAL_COUNT=0
# shellcheck disable=SC2034
HIGH_COUNT=1
# shellcheck disable=SC2034
MEDIUM_COUNT=0
# shellcheck disable=SC2034
INFO_COUNT=0
# shellcheck disable=SC2034
EXCLUDE_PATTERNS="insecure-skip-verify"
# shellcheck disable=SC2034
EXCLUDED_PATTERNS_USED="insecure-skip-verify"
# shellcheck disable=SC2034
EXCEPTIONS=""
# shellcheck disable=SC2034
EXCEPTIONS_USED=""
# shellcheck disable=SC2034
INLINE_SUPPRESSION_COUNT=0

output=$(generate_summary "high")
assert_contains "CLI audit shows exclusion audit header" "Exclusion audit" "$output"
assert_contains "CLI audit shows suppressed pattern" "suppressed" "$output"

# Cleanup exclusion state
# shellcheck disable=SC2034
EXCLUDE_PATTERNS=""
# shellcheck disable=SC2034
EXCLUDED_PATTERNS_USED=""
# shellcheck disable=SC2034
INLINE_SUPPRESSION_COUNT=0

# --- has_exclusion_config branch tests ---
echo "  --- has_exclusion_config Branch Tests ---"

# shellcheck disable=SC2034
GITHUB_ACTIONS=true
source "$ROOT_DIR/lib/utils.sh"

# Test: EXCEPTIONS-only triggers audit
FINDINGS=()
FINDINGS+=("test-high|HIGH|Test|Desc|test.go|10|code")
# shellcheck disable=SC2034
CRITICAL_COUNT=0
# shellcheck disable=SC2034
HIGH_COUNT=1
# shellcheck disable=SC2034
MEDIUM_COUNT=0
# shellcheck disable=SC2034
INFO_COUNT=0
# shellcheck disable=SC2034
EXCLUDE_PATTERNS=""
# shellcheck disable=SC2034
EXCLUDED_PATTERNS_USED=""
# shellcheck disable=SC2034
EXCEPTIONS="min-version-tls10:legacy/"
# shellcheck disable=SC2034
EXCEPTIONS_USED=""
# shellcheck disable=SC2034
INLINE_SUPPRESSION_COUNT=0

unset GITHUB_STEP_SUMMARY
output=$(generate_summary "high")
assert_contains "EXCEPTIONS-only triggers audit section" "Exclusion Audit" "$output"

# Test: INLINE_SUPPRESSION_COUNT-only triggers audit
# shellcheck disable=SC2034
EXCLUDE_PATTERNS=""
# shellcheck disable=SC2034
EXCEPTIONS=""
# shellcheck disable=SC2034
INLINE_SUPPRESSION_COUNT=5

output=$(generate_summary "high")
assert_contains "Inline-only triggers audit section" "5 finding(s) suppressed" "$output"

# --- in_csv_list direct tests ---
echo "  --- in_csv_list Tests ---"

if in_csv_list "go" "go,python,nodejs"; then
	assert_equals "in_csv_list finds item at start" "true" "true"
else
	assert_equals "in_csv_list finds item at start" "true" "false"
fi

if in_csv_list "nodejs" "go,python,nodejs"; then
	assert_equals "in_csv_list finds item at end" "true" "true"
else
	assert_equals "in_csv_list finds item at end" "true" "false"
fi

if in_csv_list "go" "go"; then
	assert_equals "in_csv_list finds single item" "true" "true"
else
	assert_equals "in_csv_list finds single item" "true" "false"
fi

if in_csv_list "go" "golang,python"; then
	assert_equals "in_csv_list rejects substring" "false" "true"
else
	assert_equals "in_csv_list rejects substring" "false" "false"
fi

if in_csv_list "go" ""; then
	assert_equals "in_csv_list rejects empty haystack" "false" "true"
else
	assert_equals "in_csv_list rejects empty haystack" "false" "false"
fi

# Cleanup exclusion state
# shellcheck disable=SC2034
EXCLUDE_PATTERNS=""
# shellcheck disable=SC2034
EXCLUDED_PATTERNS_USED=""
# shellcheck disable=SC2034
EXCEPTIONS=""
# shellcheck disable=SC2034
EXCEPTIONS_USED=""
# shellcheck disable=SC2034
INLINE_SUPPRESSION_COUNT=0

# Restore GitHub Actions mode for subsequent test files
# shellcheck disable=SC2034
GITHUB_ACTIONS=true
source "$ROOT_DIR/lib/utils.sh"
