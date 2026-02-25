#!/usr/bin/env bash
# test_utils.sh - Utility function tests

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
