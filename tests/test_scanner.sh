#!/usr/bin/env bash
# test_scanner.sh - Scanner unit tests

# Source library modules
source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/lib/scanner.sh"

echo "  --- Scanner Tests ---"

# Reset state
FINDINGS=()

# Test: Go scanning finds expected patterns
source "$ROOT_DIR/patterns/go.sh"
scan_language "$ROOT_DIR/testdata/go" "go" "" ""

assert_greater_than "Go scan finds findings" 0 "$(get_findings_count)"

# Verify specific findings
found_insecure_skip=false
for finding in "${FINDINGS[@]}"; do
	if [[ "$finding" == *"insecure-skip-verify"* ]]; then
		found_insecure_skip=true
		break
	fi
done
assert_equals "Go scan detects InsecureSkipVerify" "true" "$found_insecure_skip"

# Verify hardcoded-tls-config finding
found_hardcoded=false
for finding in "${FINDINGS[@]}"; do
	if [[ "$finding" == *"hardcoded-tls-config"* ]]; then
		found_hardcoded=true
		break
	fi
done
assert_equals "Go scan detects hardcoded tls.Config" "true" "$found_hardcoded"

# Reset state for Python
FINDINGS=()

# Test: Python scanning finds expected patterns
source "$ROOT_DIR/patterns/python.sh"
scan_language "$ROOT_DIR/testdata/python" "python" "" ""

assert_greater_than "Python scan finds findings" 0 "$(get_findings_count)"

# Reset state for Node.js
FINDINGS=()

# Test: Node.js scanning finds expected patterns
source "$ROOT_DIR/patterns/nodejs.sh"
scan_language "$ROOT_DIR/testdata/nodejs" "nodejs" "" ""

assert_greater_than "Node.js scan finds findings" 0 "$(get_findings_count)"

# Reset state for C++
FINDINGS=()

# Test: C++ scanning finds expected patterns
source "$ROOT_DIR/patterns/cpp.sh"
scan_language "$ROOT_DIR/testdata/cpp" "cpp" "" ""

assert_greater_than "C++ scan finds findings" 0 "$(get_findings_count)"

# Reset state for exclude patterns test
FINDINGS=()

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
