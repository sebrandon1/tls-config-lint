#!/usr/bin/env bash
# test_detect.sh - Language detection tests

# Source library modules
source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/lib/detect.sh"

echo "  --- Language Detection Tests ---"

# Test: Detect Go from testdata
result=$(detect_languages "$ROOT_DIR/testdata/go" 2>/dev/null)
assert_contains "Detects Go from .go files" "go" "$result"

# Test: Detect Python from testdata
result=$(detect_languages "$ROOT_DIR/testdata/python" 2>/dev/null)
assert_contains "Detects Python from .py files" "python" "$result"

# Test: Detect Node.js from testdata
result=$(detect_languages "$ROOT_DIR/testdata/nodejs" 2>/dev/null)
assert_contains "Detects Node.js from .js files" "nodejs" "$result"

# Test: Detect C++ from testdata
result=$(detect_languages "$ROOT_DIR/testdata/cpp" 2>/dev/null)
assert_contains "Detects C++ from .cpp files" "cpp" "$result"

# Test: Empty directory returns nothing
TEMP_DIR=$(mktemp -d)
result=$(detect_languages "$TEMP_DIR" 2>/dev/null)
assert_equals "Empty dir returns empty string" "" "$result"
rmdir "$TEMP_DIR"

# Test: Severity comparison helpers
source "$ROOT_DIR/lib/utils.sh"

echo "  --- Severity Helper Tests ---"

assert_equals "Severity level of critical is 4" "4" "$(severity_level "critical")"
assert_equals "Severity level of CRITICAL is 4" "4" "$(severity_level "CRITICAL")"
assert_equals "Severity level of high is 3" "3" "$(severity_level "high")"
assert_equals "Severity level of medium is 2" "2" "$(severity_level "medium")"
assert_equals "Severity level of info is 1" "1" "$(severity_level "info")"

# Test meets_threshold
if meets_threshold "CRITICAL" "high"; then
	assert_equals "CRITICAL meets HIGH threshold" "true" "true"
else
	assert_equals "CRITICAL meets HIGH threshold" "true" "false"
fi

if meets_threshold "INFO" "high"; then
	assert_equals "INFO does not meet HIGH threshold" "false" "true"
else
	assert_equals "INFO does not meet HIGH threshold" "false" "false"
fi

if meets_threshold "HIGH" "high"; then
	assert_equals "HIGH meets HIGH threshold" "true" "true"
else
	assert_equals "HIGH meets HIGH threshold" "true" "false"
fi
