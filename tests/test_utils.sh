#!/usr/bin/env bash
# test_utils.sh - Utility function tests
# shellcheck disable=SC2218  # Functions defined via source in run_tests.sh

# Force GitHub Actions mode first
GITHUB_ACTIONS=true
# Source library modules
source "$ROOT_DIR/lib/utils.sh"

echo "  --- Utils Tests ---"

# Test: normalize_severity
assert_equals "normalize CRITICAL" "critical" "$(normalize_severity "CRITICAL")"
assert_equals "normalize HIGH" "high" "$(normalize_severity "HIGH")"
assert_equals "normalize Medium" "medium" "$(normalize_severity "Medium")"
assert_equals "normalize info" "info" "$(normalize_severity "info")"

# Test: severity_level edge case
assert_equals "Unknown severity returns 0" "0" "$(severity_level "unknown")"
assert_equals "Empty severity returns 0" "0" "$(severity_level "")"

# Test: meets_threshold boundary cases
if meets_threshold "medium" "medium"; then
	assert_equals "Same severity meets threshold" "true" "true"
else
	assert_equals "Same severity meets threshold" "true" "false"
fi

if meets_threshold "info" "critical"; then
	assert_equals "info does not meet critical threshold" "false" "true"
else
	assert_equals "info does not meet critical threshold" "false" "false"
fi

if meets_threshold "critical" "info"; then
	assert_equals "critical meets info threshold" "true" "true"
else
	assert_equals "critical meets info threshold" "true" "false"
fi

# Test: csv_to_list trims spaces
result=$(csv_to_list "a , b , c")
assert_equals "csv_to_list trims spaces" "a,b,c" "$result"

result=$(csv_to_list "single")
assert_equals "csv_to_list handles single value" "single" "$result"

# Test: in_csv_list
if in_csv_list "go" "go,python,nodejs"; then
	assert_equals "in_csv_list finds existing value" "true" "true"
else
	assert_equals "in_csv_list finds existing value" "true" "false"
fi

if in_csv_list "rust" "go,python,nodejs"; then
	assert_equals "in_csv_list rejects missing value" "false" "true"
else
	assert_equals "in_csv_list rejects missing value" "false" "false"
fi

# Test: CLI_MODE detection
assert_equals "GITHUB_ACTIONS=true sets CLI_MODE=false" "false" "$CLI_MODE"

# Test: GHA log functions produce workflow commands
output=$(log_info "test message")
assert_contains "GHA log_info produces ::notice" "::notice::" "$output"
output=$(log_warning "test message")
assert_contains "GHA log_warning produces ::warning" "::warning::" "$output"
output=$(log_error "test message")
assert_contains "GHA log_error produces ::error" "::error::" "$output"

# --- CLI mode log tests ---
echo "  --- Utils Tests (CLI mode) ---"

unset GITHUB_ACTIONS
source "$ROOT_DIR/lib/utils.sh"

assert_equals "Unset GITHUB_ACTIONS sets CLI_MODE=true" "true" "$CLI_MODE"

output=$(log_info "test message")
assert_contains "CLI log_info shows [INFO]" "[INFO]" "$output"
assert_contains "CLI log_info shows message" "test message" "$output"

output=$(log_warning "test message")
assert_contains "CLI log_warning shows [WARN]" "[WARN]" "$output"

output=$(log_error "test message")
assert_contains "CLI log_error shows [ERROR]" "[ERROR]" "$output"

# CLI debug should be silent without DEBUG set
unset DEBUG
output=$(log_debug "test message")
assert_equals "CLI log_debug silent without DEBUG" "" "$output"

# CLI debug should produce output with DEBUG set
# shellcheck disable=SC2034  # Used by log_debug
DEBUG=1
output=$(log_debug "test message")
assert_contains "CLI log_debug shows [DEBUG] with DEBUG=1" "[DEBUG]" "$output"
unset DEBUG

# Restore GitHub Actions mode for subsequent test files
# shellcheck disable=SC2034  # Used by utils.sh on re-source
GITHUB_ACTIONS=true
source "$ROOT_DIR/lib/utils.sh"
