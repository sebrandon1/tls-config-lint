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

# --- Per-File Exception Tests ---
echo "  --- Per-File Exception Tests ---"

# Reset state
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
# shellcheck disable=SC2034
MEDIUM_COUNT=0
# shellcheck disable=SC2034
INFO_COUNT=0

# Test: is_path_excluded with exact file match
if is_path_excluded "insecure-skip-verify" "go/insecure.go" "insecure-skip-verify:go/insecure.go"; then
	assert_equals "Exact file exception matches" "true" "true"
else
	assert_equals "Exact file exception matches" "true" "false"
fi

# Test: is_path_excluded with directory prefix
if is_path_excluded "insecure-skip-verify" "go/insecure.go" "insecure-skip-verify:go/"; then
	assert_equals "Directory exception matches" "true" "true"
else
	assert_equals "Directory exception matches" "true" "false"
fi

# Test: is_path_excluded does not match wrong pattern
if is_path_excluded "min-version-tls10" "go/insecure.go" "insecure-skip-verify:go/insecure.go"; then
	assert_equals "Wrong pattern does not match" "false" "true"
else
	assert_equals "Wrong pattern does not match" "false" "false"
fi

# Test: is_path_excluded does not match wrong file
if is_path_excluded "insecure-skip-verify" "other.go" "insecure-skip-verify:go/insecure.go"; then
	assert_equals "Wrong file does not match" "false" "true"
else
	assert_equals "Wrong file does not match" "false" "false"
fi

# Test: is_path_excluded with glob pattern
if is_path_excluded "insecure-skip-verify" "go/insecure.go" "insecure-skip-verify:go/*.go"; then
	assert_equals "Glob exception matches" "true" "true"
else
	assert_equals "Glob exception matches" "true" "false"
fi

# Test: is_path_excluded with empty exceptions
if is_path_excluded "insecure-skip-verify" "go/insecure.go" ""; then
	assert_equals "Empty exceptions do not match" "false" "true"
else
	assert_equals "Empty exceptions do not match" "false" "false"
fi

# Test: Scan with per-file exception suppresses finding in specified file only
source "$ROOT_DIR/patterns/go.sh"
# shellcheck disable=SC2034  # Used by scan_language via is_path_excluded
EXCEPTIONS="insecure-skip-verify:go/insecure.go"
scan_language "$ROOT_DIR/testdata/go" "go" "" ""

# insecure-skip-verify should NOT appear for go/insecure.go
found_in_excepted=false
for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
	IFS='|' read -r fid _ _ _ ffile _ _ _ <<<"$finding"
	if [[ "$fid" == "insecure-skip-verify" ]] && [[ "$ffile" == "go/insecure.go" ]]; then
		found_in_excepted=true
		break
	fi
done
assert_equals "Exception suppresses pattern in specified file" "false" "$found_in_excepted"

# insecure-skip-verify SHOULD still appear for config:prod.go (colon in filename)
found_in_other=false
for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
	IFS='|' read -r fid _ _ _ ffile _ _ _ <<<"$finding"
	if [[ "$fid" == "insecure-skip-verify" ]] && [[ "$ffile" != "go/insecure.go" ]]; then
		found_in_other=true
		break
	fi
done
assert_equals "Exception does not suppress pattern in other files" "true" "$found_in_other"

# Cleanup
# shellcheck disable=SC2034  # Reset for subsequent tests
EXCEPTIONS=""

# --- Severity Override Tests ---
echo "  --- Severity Override Tests ---"

# Reset state
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
# shellcheck disable=SC2034
MEDIUM_COUNT=0
# shellcheck disable=SC2034
INFO_COUNT=0

# Test: get_severity_override with matching pattern
result=$(get_severity_override "insecure-skip-verify" "insecure-skip-verify:medium")
assert_equals "Override returns matching severity" "medium" "$result"

# Test: get_severity_override with no match
result=$(get_severity_override "min-version-tls10" "insecure-skip-verify:medium")
assert_equals "Override returns empty for non-matching pattern" "" "$result"

# Test: get_severity_override with empty overrides
result=$(get_severity_override "insecure-skip-verify" "")
assert_equals "Override returns empty for empty overrides" "" "$result"

# Test: get_severity_override with multiple entries
result=$(get_severity_override "min-version-tls10" "insecure-skip-verify:medium,min-version-tls10:info")
assert_equals "Override matches correct entry from multiple" "info" "$result"

# Test: Scan with severity override changes finding severity
source "$ROOT_DIR/patterns/go.sh"
# shellcheck disable=SC2034  # Used by scan_pattern via get_severity_override
SEVERITY_OVERRIDES="insecure-skip-verify:medium"
scan_language "$ROOT_DIR/testdata/go" "go" "" ""

# Verify overridden severity appears in findings
found_overridden=false
for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
	IFS='|' read -r fid fsev _ _ _ _ _ _ <<<"$finding"
	if [[ "$fid" == "insecure-skip-verify" ]]; then
		if [[ "$(normalize_severity "$fsev")" == "medium" ]]; then
			found_overridden=true
		fi
		break
	fi
done
assert_equals "Severity override applied in scan findings" "true" "$found_overridden"

# Verify counter reflects override (insecure-skip-verify was CRITICAL, now MEDIUM)
assert_equals "Override shifts count away from critical" "0" "$(
	count=0
	for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
		IFS='|' read -r fid fsev _ _ _ _ _ _ <<<"$finding"
		if [[ "$fid" == "insecure-skip-verify" ]] && [[ "$(normalize_severity "$fsev")" == "critical" ]]; then
			count=$((count + 1))
		fi
	done
	echo "$count"
)"

# Verify MEDIUM_COUNT incremented from overridden findings
assert_greater_than "MEDIUM_COUNT reflects overridden severity" 0 "$MEDIUM_COUNT"

# Verify non-overridden patterns retain original severity
found_original=false
for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
	IFS='|' read -r fid fsev _ _ _ _ _ _ <<<"$finding"
	if [[ "$fid" == "min-version-tls10" ]] && [[ "$(normalize_severity "$fsev")" == "high" ]]; then
		found_original=true
		break
	fi
done
assert_equals "Non-overridden pattern retains original severity" "true" "$found_original"

# Cleanup
# shellcheck disable=SC2034  # Reset for subsequent tests
SEVERITY_OVERRIDES=""

# --- Inline Suppression Tests ---
echo "  --- Inline Suppression Tests ---"

# Reset state
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
# shellcheck disable=SC2034
MEDIUM_COUNT=0
# shellcheck disable=SC2034
INFO_COUNT=0

# Test: is_line_suppressed with bare tls-lint:ignore
if is_line_suppressed "insecure-skip-verify" "InsecureSkipVerify: true // tls-lint:ignore"; then
	assert_equals "Bare ignore suppresses any pattern" "true" "true"
else
	assert_equals "Bare ignore suppresses any pattern" "true" "false"
fi

# Test: is_line_suppressed with targeted pattern
if is_line_suppressed "insecure-skip-verify" "InsecureSkipVerify: true // tls-lint:ignore:insecure-skip-verify"; then
	assert_equals "Targeted ignore suppresses matching pattern" "true" "true"
else
	assert_equals "Targeted ignore suppresses matching pattern" "true" "false"
fi

# Test: is_line_suppressed with non-matching targeted pattern
if is_line_suppressed "insecure-skip-verify" "InsecureSkipVerify: true // tls-lint:ignore:min-version-tls10"; then
	assert_equals "Targeted ignore does not suppress non-matching pattern" "false" "true"
else
	assert_equals "Targeted ignore does not suppress non-matching pattern" "false" "false"
fi

# Test: is_line_suppressed with no directive
if is_line_suppressed "insecure-skip-verify" "InsecureSkipVerify: true"; then
	assert_equals "No directive does not suppress" "false" "true"
else
	assert_equals "No directive does not suppress" "false" "false"
fi

# Test: is_line_suppressed targeted does not match prefix of longer pattern ID
if is_line_suppressed "protocol-tlsv11" "ctx = ssl.PROTOCOL_TLSv1_1 # tls-lint:ignore:protocol-tlsv1"; then
	assert_equals "Targeted ignore must not match prefix of longer ID" "false" "true"
else
	assert_equals "Targeted ignore must not match prefix of longer ID" "false" "false"
fi

# Test: is_line_suppressed with Python-style comment
if is_line_suppressed "verify-false" "verify=False  # tls-lint:ignore"; then
	assert_equals "Python comment suppresses" "true" "true"
else
	assert_equals "Python comment suppresses" "true" "false"
fi

# Test: Scan with inline suppression — suppressed lines excluded
source "$ROOT_DIR/patterns/go.sh"
# shellcheck disable=SC2034  # Reset for subsequent tests
SEVERITY_OVERRIDES=""
scan_language "$ROOT_DIR/testdata/go" "go" "" ""

# The suppressed InsecureSkipVerify (blanket ignore) should not appear
found_suppressed_blanket=false
for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
	IFS='|' read -r fid _ _ _ _ _ fmatch _ <<<"$finding"
	if [[ "$fid" == "insecure-skip-verify" ]] && [[ "$fmatch" == *"tls-lint:ignore"* ]]; then
		found_suppressed_blanket=true
		break
	fi
done
assert_equals "Blanket inline suppression excluded from findings" "false" "$found_suppressed_blanket"

# The suppressed min-version-tls10 (targeted ignore) should not appear
found_suppressed_targeted=false
for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
	IFS='|' read -r fid _ _ _ _ _ fmatch _ <<<"$finding"
	if [[ "$fid" == "min-version-tls10" ]] && [[ "$fmatch" == *"tls-lint:ignore"* ]]; then
		found_suppressed_targeted=true
		break
	fi
done
assert_equals "Targeted inline suppression excluded from findings" "false" "$found_suppressed_targeted"

# Non-suppressed findings still present
found_unsuppressed=false
for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
	IFS='|' read -r fid _ _ _ _ _ _ _ <<<"$finding"
	if [[ "$fid" == "insecure-skip-verify" ]]; then
		found_unsuppressed=true
		break
	fi
done
assert_equals "Non-suppressed findings still present" "true" "$found_unsuppressed"

# Blanket-suppressed pattern should have zero matches with tls-lint:ignore in match text
blanket_leak=false
for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
	IFS='|' read -r fid _ _ _ _ _ fmatch _ <<<"$finding"
	if [[ "$fid" == "insecure-skip-verify" ]] && [[ "$fmatch" == *"tls-lint:ignore"* ]]; then
		blanket_leak=true
		break
	fi
done
assert_equals "Blanket-suppressed pattern does not leak" "false" "$blanket_leak"

# Python inline suppression integration test
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
# shellcheck disable=SC2034
MEDIUM_COUNT=0
# shellcheck disable=SC2034
INFO_COUNT=0

source "$ROOT_DIR/patterns/python.sh"
scan_language "$ROOT_DIR/testdata/python" "python" "" ""

found_python_suppressed=false
for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
	IFS='|' read -r _ _ _ _ _ _ fmatch _ <<<"$finding"
	if [[ "$fmatch" == *"tls-lint:ignore"* ]]; then
		found_python_suppressed=true
		break
	fi
done
assert_equals "Python inline suppression excluded from findings" "false" "$found_python_suppressed"

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
