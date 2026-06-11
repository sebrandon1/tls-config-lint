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
assert_greater_than "Go scan finds total findings" 10 "$(get_findings_count)"

# Verify specific findings
found_insecure_skip=false
for finding in "${FINDINGS[@]}"; do
	if [[ "$finding" == *"insecure-skip-verify"* ]]; then
		found_insecure_skip=true
		break
	fi
done
assert_equals "Go scan detects InsecureSkipVerify" "true" "$found_insecure_skip"

# Test: Files with colons in names are parsed correctly
found_colon_file=false
for finding in "${FINDINGS[@]}"; do
	IFS='|' read -r _ _ _ _ ffile _ _ <<<"$finding"
	if [[ "$ffile" == *"config:prod.go"* ]]; then
		found_colon_file=true
		break
	fi
done
assert_equals "Scanner handles colons in filenames" "true" "$found_colon_file"

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
assert_greater_than "Python scan finds total findings" 13 "$(get_findings_count)"

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
assert_greater_than "Node.js scan finds total findings" 10 "$(get_findings_count)"

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
assert_greater_than "C++ scan finds total findings" 8 "$(get_findings_count)"

# Reset state for Java
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0

# Test: Java scanning finds expected patterns
source "$ROOT_DIR/patterns/java.sh"
scan_language "$ROOT_DIR/testdata/java" "java" "" ""

assert_greater_than "Java scan finds critical findings" 0 "$CRITICAL_COUNT"
assert_greater_than "Java scan finds total findings" 15 "$(get_findings_count)"

# Reset state for Rust
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0

# Test: Rust scanning finds expected patterns
source "$ROOT_DIR/patterns/rust.sh"
scan_language "$ROOT_DIR/testdata/rust" "rust" "" ""

assert_greater_than "Rust scan finds critical findings" 0 "$CRITICAL_COUNT"
assert_greater_than "Rust scan finds total findings" 10 "$(get_findings_count)"

# Reset state for exclude patterns test
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
# shellcheck disable=SC2034  # Used by scanner.sh
MEDIUM_COUNT=0
# shellcheck disable=SC2034  # Used by scanner.sh
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

# --- False Positive Tests ---
# Scan secure code files that should NOT trigger critical/high findings.
# Each secure file contains comments and strings mentioning insecure patterns
# plus properly configured TLS — none should produce critical/high matches.

echo "  --- False Positive Tests ---"

# Go secure code
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0
fp_dir=$(mktemp -d)
cp "$ROOT_DIR/testdata/go/secure.go" "$fp_dir/"
source "$ROOT_DIR/patterns/go.sh"
scan_language "$fp_dir" "go" "" ""
assert_equals "Go secure code: no critical findings" "0" "$CRITICAL_COUNT"
assert_equals "Go secure code: no high findings" "0" "$HIGH_COUNT"
rm -rf "$fp_dir"

# Python secure code
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0
fp_dir=$(mktemp -d)
cp "$ROOT_DIR/testdata/python/secure.py" "$fp_dir/"
source "$ROOT_DIR/patterns/python.sh"
scan_language "$fp_dir" "python" "" ""
assert_equals "Python secure code: no critical findings" "0" "$CRITICAL_COUNT"
assert_equals "Python secure code: no high findings" "0" "$HIGH_COUNT"
rm -rf "$fp_dir"

# Node.js secure code
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0
fp_dir=$(mktemp -d)
cp "$ROOT_DIR/testdata/nodejs/secure.js" "$fp_dir/"
source "$ROOT_DIR/patterns/nodejs.sh"
scan_language "$fp_dir" "nodejs" "" ""
assert_equals "Node.js secure code: no critical findings" "0" "$CRITICAL_COUNT"
assert_equals "Node.js secure code: no high findings" "0" "$HIGH_COUNT"
rm -rf "$fp_dir"

# C++ secure code
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0
fp_dir=$(mktemp -d)
cp "$ROOT_DIR/testdata/cpp/secure.cpp" "$fp_dir/"
source "$ROOT_DIR/patterns/cpp.sh"
scan_language "$fp_dir" "cpp" "" ""
assert_equals "C++ secure code: no critical findings" "0" "$CRITICAL_COUNT"
assert_equals "C++ secure code: no high findings" "0" "$HIGH_COUNT"
rm -rf "$fp_dir"

# Java secure code
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0
fp_dir=$(mktemp -d)
cp "$ROOT_DIR/testdata/java/Secure.java" "$fp_dir/"
source "$ROOT_DIR/patterns/java.sh"
scan_language "$fp_dir" "java" "" ""
assert_equals "Java secure code: no critical findings" "0" "$CRITICAL_COUNT"
assert_equals "Java secure code: no high findings" "0" "$HIGH_COUNT"
rm -rf "$fp_dir"

# Rust secure code
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
# shellcheck disable=SC2034  # Used by scanner.sh
MEDIUM_COUNT=0
# shellcheck disable=SC2034  # Used by scanner.sh
INFO_COUNT=0
fp_dir=$(mktemp -d)
cp "$ROOT_DIR/testdata/rust/secure.rs" "$fp_dir/"
source "$ROOT_DIR/patterns/rust.sh"
scan_language "$fp_dir" "rust" "" ""
assert_equals "Rust secure code: no critical findings" "0" "$CRITICAL_COUNT"
assert_equals "Rust secure code: no high findings" "0" "$HIGH_COUNT"
rm -rf "$fp_dir"
