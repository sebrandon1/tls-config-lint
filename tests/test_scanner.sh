#!/usr/bin/env bash
# test_scanner.sh - Scanner unit tests

# Source library modules
source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/lib/scanner.sh"

echo "  --- Scanner Tests ---"

# Reset state
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0

# Test: Go scanning finds expected patterns
source "$ROOT_DIR/patterns/go.sh"
scan_language "$ROOT_DIR/testdata/go" "go" "" ""

assert_greater_than "Go scan finds critical findings" 0 "$CRITICAL_COUNT"
assert_greater_than "Go scan finds high findings" 0 "$HIGH_COUNT"
assert_greater_than "Go scan finds total findings" 5 "$(get_findings_count)"

# Verify specific findings
found_insecure_skip=false
for finding in "${FINDINGS[@]}"; do
	if [[ "$finding" == *"insecure-skip-verify"* ]]; then
		found_insecure_skip=true
		break
	fi
done
assert_equals "Go scan detects InsecureSkipVerify" "true" "$found_insecure_skip"

# Reset state for Python
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0

# Test: Python scanning finds expected patterns
source "$ROOT_DIR/patterns/python.sh"
scan_language "$ROOT_DIR/testdata/python" "python" "" ""

assert_greater_than "Python scan finds critical findings" 0 "$CRITICAL_COUNT"
assert_greater_than "Python scan finds total findings" 5 "$(get_findings_count)"

# Reset state for Node.js
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0

# Test: Node.js scanning finds expected patterns
source "$ROOT_DIR/patterns/nodejs.sh"
scan_language "$ROOT_DIR/testdata/nodejs" "nodejs" "" ""

assert_greater_than "Node.js scan finds critical findings" 0 "$CRITICAL_COUNT"
assert_greater_than "Node.js scan finds total findings" 4 "$(get_findings_count)"

# Reset state for C++
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0

# Test: C++ scanning finds expected patterns
source "$ROOT_DIR/patterns/cpp.sh"
scan_language "$ROOT_DIR/testdata/cpp" "cpp" "" ""

assert_greater_than "C++ scan finds critical findings" 0 "$CRITICAL_COUNT"
assert_greater_than "C++ scan finds total findings" 5 "$(get_findings_count)"

# Reset state for exclude patterns test
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0

# Test: Pattern exclusion works
source "$ROOT_DIR/patterns/go.sh"
scan_language "$ROOT_DIR/testdata/go" "go" "" "insecure-skip-verify"

found_excluded=false
for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
	if [[ "$finding" == *"insecure-skip-verify"* ]]; then
		found_excluded=true
		break
	fi
done
assert_equals "Excluded pattern not found in results" "false" "$found_excluded"
