#!/usr/bin/env bash
# test_annotations.sh - Annotation emitter tests

# Source library modules
source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/lib/scanner.sh"
source "$ROOT_DIR/lib/annotations.sh"

echo "  --- Annotations Tests ---"

# Set up test findings
FINDINGS=()
FINDINGS+=("test-critical|CRITICAL|Test Critical|Critical test finding|test.go|10|some code")
FINDINGS+=("test-high|HIGH|Test High|High test finding|test.go|15|some code")
FINDINGS+=("test-medium|MEDIUM|Test Medium|Medium test finding|test.py|20|some code")
FINDINGS+=("test-info|INFO|Test Info|Info test finding|test.js|30|some code")

# Capture annotation output
output=$(emit_annotations)

# Test: CRITICAL findings produce ::error annotations
assert_contains "CRITICAL produces ::error" "::error" "$output"

# Test: HIGH findings produce ::error annotations
high_line=$(echo "$output" | grep "test-high")
assert_contains "HIGH produces ::error" "::error" "$high_line"

# Test: MEDIUM findings produce ::warning annotations
medium_line=$(echo "$output" | grep "test-medium")
assert_contains "MEDIUM produces ::warning" "::warning" "$medium_line"

# Test: INFO findings produce ::notice annotations
info_line=$(echo "$output" | grep "test-info")
assert_contains "INFO produces ::notice" "::notice" "$info_line"

# Test: Annotations include file and line number
assert_contains "Annotations include file path" "file=test.go" "$output"
assert_contains "Annotations include line number" "line=10" "$output"

# Test: Empty findings produce no output
FINDINGS=()
empty_output=$(emit_annotations)
assert_equals "Empty findings produce no output" "" "$empty_output"
