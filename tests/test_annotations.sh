#!/usr/bin/env bash
# test_annotations.sh - Annotation emitter tests

# Force GitHub Actions mode for existing tests
GITHUB_ACTIONS=true

# Source library modules
source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/lib/scanner.sh"
source "$ROOT_DIR/lib/annotations.sh"

echo "  --- Annotations Tests (GitHub Actions mode) ---"

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

# --- CLI mode tests ---
echo "  --- Annotations Tests (CLI mode) ---"

unset GITHUB_ACTIONS
source "$ROOT_DIR/lib/utils.sh"

FINDINGS=()
FINDINGS+=("test-critical|CRITICAL|Test Critical|Critical test finding|test.go|10|some code")
FINDINGS+=("test-high|HIGH|Test High|High test finding|test.go|15|some code")
FINDINGS+=("test-medium|MEDIUM|Test Medium|Medium test finding|test.py|20|some code")
FINDINGS+=("test-info|INFO|Test Info|Info test finding|test.js|30|some code")

output=$(emit_annotations)

# CLI mode should NOT produce ::error/::warning/::notice
assert_contains "CLI mode shows CRITICAL severity" "CRITICAL" "$output"
assert_contains "CLI mode shows file:line format" "test.go:10" "$output"
assert_contains "CLI mode shows finding name" "Test High" "$output"
assert_contains "CLI mode shows INFO severity" "INFO" "$output"

# Verify no GitHub workflow commands in CLI output
if echo "$output" | grep -q "^::"; then
	assert_equals "CLI mode produces no workflow commands" "true" "false"
else
	assert_equals "CLI mode produces no workflow commands" "true" "true"
fi

# Test: Empty findings produce no output in CLI mode
FINDINGS=()
empty_output=$(emit_annotations)
assert_equals "CLI empty findings produce no output" "" "$empty_output"

# --- Debug Mode Tests ---
echo "  --- Annotations Tests (Debug mode) ---"

# Test: GHA debug mode includes match and regex in annotations
# shellcheck disable=SC2034
GITHUB_ACTIONS=true
source "$ROOT_DIR/lib/utils.sh"

FINDINGS=()
FINDINGS+=("test-critical|CRITICAL|Test Critical|Critical finding|test.go|10|InsecureSkipVerify: true")
# shellcheck disable=SC2034
FINDING_REGEXES=()
FINDING_REGEXES+=("InsecureSkipVerify[[:space:]]*:[[:space:]]*true")

# shellcheck disable=SC2034
DEBUG=1
output=$(emit_annotations)
assert_contains "GHA debug includes match text" "match: InsecureSkipVerify: true" "$output"
assert_contains "GHA debug includes regex" "regex: InsecureSkipVerify" "$output"

# Test: GHA non-debug does not include match/regex
unset DEBUG
output=$(emit_annotations)
if echo "$output" | grep -q "regex:"; then
	assert_equals "GHA non-debug excludes regex" "true" "false"
else
	assert_equals "GHA non-debug excludes regex" "true" "true"
fi

# Test: CLI debug mode includes match and regex
unset GITHUB_ACTIONS
source "$ROOT_DIR/lib/utils.sh"

FINDINGS=()
FINDINGS+=("test-critical|CRITICAL|Test Critical|Critical finding|test.go|10|InsecureSkipVerify: true")
FINDING_REGEXES=()
FINDING_REGEXES+=("InsecureSkipVerify[[:space:]]*:[[:space:]]*true")

# shellcheck disable=SC2034
DEBUG=1
output=$(emit_annotations)
assert_contains "CLI debug includes Match line" "Match: InsecureSkipVerify: true" "$output"
assert_contains "CLI debug includes Regex line" "Regex: InsecureSkipVerify" "$output"

# Test: CLI non-debug does not include Match/Regex
unset DEBUG
output=$(emit_annotations)
if echo "$output" | grep -q "Regex:"; then
	assert_equals "CLI non-debug excludes regex" "true" "false"
else
	assert_equals "CLI non-debug excludes regex" "true" "true"
fi
unset DEBUG

# Restore GitHub Actions mode for subsequent test files
# shellcheck disable=SC2034
GITHUB_ACTIONS=true
source "$ROOT_DIR/lib/utils.sh"
