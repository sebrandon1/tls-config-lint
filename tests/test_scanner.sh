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

httpx_ids=0
for finding in "${FINDINGS[@]+${FINDINGS[@]}}"; do
	if [[ "$finding" == httpx-* ]]; then
		httpx_ids=$((httpx_ids + 1))
	fi
done
assert_greater_than "Python scan detects httpx-specific findings" 2 "$httpx_ids"

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

nodejs_scanned_files=$(printf '%s\n' "${FINDINGS[@]+"${FINDINGS[@]}"}")
assert_contains "Node.js scan covers .tsx files" "insecure.tsx" "$nodejs_scanned_files"

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

cpp_scanned_files=$(printf '%s\n' "${FINDINGS[@]+"${FINDINGS[@]}"}")
assert_contains "C++ scan covers plain .c files" "|insecure.c|" "$cpp_scanned_files"

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

spring_ids=0
for finding in "${FINDINGS[@]+${FINDINGS[@]}}"; do
	if [[ "$finding" == spring-* ]]; then
		spring_ids=$((spring_ids + 1))
	fi
done
assert_greater_than "Java scan detects Spring-specific findings" 3 "$spring_ids"

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

# Reset state for Kotlin, C#, PHP, and Ruby
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0

# Test: Kotlin scanning finds expected patterns
source "$ROOT_DIR/patterns/kotlin.sh"
scan_language "$ROOT_DIR/testdata/kotlin" "kotlin" "" ""

assert_greater_than "Kotlin scan finds critical findings" 3 "$CRITICAL_COUNT"
assert_greater_than "Kotlin scan finds high findings" 0 "$HIGH_COUNT"
assert_greater_than "Kotlin scan finds total findings" 4 "$(get_findings_count)"

# Reset state for C#
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0

# Test: C# scanning finds expected patterns
source "$ROOT_DIR/patterns/csharp.sh"
scan_language "$ROOT_DIR/testdata/csharp" "csharp" "" ""

assert_greater_than "C# scan finds critical findings" 1 "$CRITICAL_COUNT"
assert_greater_than "C# scan finds high findings" 1 "$HIGH_COUNT"
assert_greater_than "C# scan finds total findings" 3 "$(get_findings_count)"

# Reset state for PHP
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0

# Test: PHP scanning finds expected patterns
source "$ROOT_DIR/patterns/php.sh"
scan_language "$ROOT_DIR/testdata/php" "php" "" ""

assert_greater_than "PHP scan finds critical findings" 4 "$CRITICAL_COUNT"
assert_greater_than "PHP scan finds total findings" 4 "$(get_findings_count)"

# Reset state for Ruby
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0

# Test: Ruby scanning finds expected patterns
source "$ROOT_DIR/patterns/ruby.sh"
scan_language "$ROOT_DIR/testdata/ruby" "ruby" "" ""

assert_greater_than "Ruby scan finds critical findings" 3 "$CRITICAL_COUNT"
assert_greater_than "Ruby scan finds high findings" 0 "$HIGH_COUNT"
assert_greater_than "Ruby scan finds total findings" 4 "$(get_findings_count)"

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

# Verify EXCLUDED_PATTERNS_USED tracking
assert_contains "EXCLUDED_PATTERNS_USED tracks excluded pattern" "insecure-skip-verify" "$EXCLUDED_PATTERNS_USED"

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

# Test: EXCEPTIONS_USED tracking with matching path
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
# shellcheck disable=SC2034
MEDIUM_COUNT=0
# shellcheck disable=SC2034
INFO_COUNT=0
# shellcheck disable=SC2034
EXCEPTIONS_USED=""

exc_dir=$(mktemp -d)
cat >"$exc_dir/insecure.go" <<'GOEOF'
package main
import "crypto/tls"
func f() { _ = &tls.Config{InsecureSkipVerify: true} }
GOEOF

source "$ROOT_DIR/patterns/go.sh"
# shellcheck disable=SC2034
EXCEPTIONS="insecure-skip-verify:insecure.go"
scan_language "$exc_dir" "go" "" ""

assert_contains "EXCEPTIONS_USED tracks excepted pattern" "insecure-skip-verify:" "$EXCEPTIONS_USED"
# shellcheck disable=SC2034
EXCEPTIONS=""
# shellcheck disable=SC2034
EXCEPTIONS_USED=""
rm -rf "$exc_dir"

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

# Verify INLINE_SUPPRESSION_COUNT tracking
assert_greater_than "INLINE_SUPPRESSION_COUNT tracks suppressed lines" 0 "$INLINE_SUPPRESSION_COUNT"

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

# --- is_pattern_excluded Direct Tests ---
echo "  --- is_pattern_excluded Tests ---"

if is_pattern_excluded "insecure-skip-verify" "insecure-skip-verify,min-version-tls10"; then
	assert_equals "is_pattern_excluded matches in list" "true" "true"
else
	assert_equals "is_pattern_excluded matches in list" "true" "false"
fi

if is_pattern_excluded "verify-false" "insecure-skip-verify,min-version-tls10"; then
	assert_equals "is_pattern_excluded rejects non-member" "false" "true"
else
	assert_equals "is_pattern_excluded rejects non-member" "false" "false"
fi

if is_pattern_excluded "insecure-skip-verify" ""; then
	assert_equals "is_pattern_excluded with empty list" "false" "true"
else
	assert_equals "is_pattern_excluded with empty list" "false" "false"
fi

# --- build_* Helper Tests ---
echo "  --- Build Helper Tests ---"

# build_include_flags
assert_contains "build_include_flags go" "--include=*.go" "$(build_include_flags "go")"
assert_contains "build_include_flags python" "--include=*.py" "$(build_include_flags "python")"
assert_contains "build_include_flags nodejs includes .ts" "--include=*.ts" "$(build_include_flags "nodejs")"
assert_contains "build_include_flags cpp" "--include=*.cpp" "$(build_include_flags "cpp")"
assert_contains "build_include_flags cpp includes .c" "--include=*.c " "$(build_include_flags "cpp")"
assert_contains "build_include_flags java" "--include=*.java" "$(build_include_flags "java")"
assert_contains "build_include_flags rust" "--include=*.rs" "$(build_include_flags "rust")"
assert_contains "build_include_flags kotlin includes .kts" "--include=*.kts" "$(build_include_flags "kotlin")"
for nodejs_ext in cjs cts jsx tsx; do
	assert_contains "build_include_flags nodejs includes .$nodejs_ext" "--include=*.$nodejs_ext" "$(build_include_flags "nodejs")"
done

# file_matches_language covers the added extensions
for lang_file in cpp:src/openssl.c nodejs:src/app.cjs nodejs:src/app.cts nodejs:src/app.jsx nodejs:src/app.tsx kotlin:build.gradle.kts; do
	if file_matches_language "${lang_file%%:*}" "${lang_file#*:}"; then
		assert_equals "file_matches_language ${lang_file}" "true" "true"
	else
		assert_equals "file_matches_language ${lang_file}" "true" "false"
	fi
done
if file_matches_language "cpp" "src/notes.md"; then
	assert_equals "file_matches_language rejects unrelated extension" "false" "true"
else
	assert_equals "file_matches_language rejects unrelated extension" "false" "false"
fi

# build_test_exclude_flags
assert_contains "build_test_exclude_flags go" "--exclude=*_test.go" "$(build_test_exclude_flags "go")"
assert_contains "build_test_exclude_flags python" "--exclude=*_test.py" "$(build_test_exclude_flags "python")"
assert_contains "build_test_exclude_flags cpp includes C tests" "--exclude=*_test.c " "$(build_test_exclude_flags "cpp")"
for nodejs_test_ext in cjs cts jsx tsx; do
	assert_contains "build_test_exclude_flags nodejs includes .test.$nodejs_test_ext" "--exclude=*.test.$nodejs_test_ext" "$(build_test_exclude_flags "nodejs")"
done
assert_contains "build_test_exclude_flags csharp includes *Tests.cs" "--exclude=*Tests.cs" "$(build_test_exclude_flags "csharp")"
assert_contains "build_test_exclude_flags csharp includes *Test.cs" "--exclude=*Test.cs" "$(build_test_exclude_flags "csharp")"
assert_contains "build_test_exclude_flags kotlin includes *Spec.kt" "--exclude=*Spec.kt" "$(build_test_exclude_flags "kotlin")"
assert_contains "build_test_exclude_flags php includes *Test.php" "--exclude=*Test.php" "$(build_test_exclude_flags "php")"
assert_contains "build_test_exclude_flags ruby includes *_spec.rb" "--exclude=*_spec.rb" "$(build_test_exclude_flags "ruby")"
assert_contains "build_lang_exclude_dirs ruby excludes spec" "--exclude-dir=spec" "$(build_lang_exclude_dirs "ruby")"

# file_matches_test_exclusion follows each ecosystem's own convention
for test_file in csharp:FooTests.cs csharp:FooTest.cs kotlin:FooTest.kt kotlin:FooTests.kt kotlin:FooSpec.kt php:FooTest.php ruby:foo_spec.rb ruby:foo_test.rb ruby:test_foo.rb; do
	if file_matches_test_exclusion "${test_file%%:*}" "${test_file#*:}"; then
		assert_equals "test exclusion matches ${test_file}" "true" "true"
	else
		assert_equals "test exclusion matches ${test_file}" "true" "false"
	fi
done
for prod_file in csharp:TestClient.cs kotlin:TestHarness.kt php:contest.php ruby:spec_helper.rb; do
	if file_matches_test_exclusion "${prod_file%%:*}" "${prod_file#*:}"; then
		assert_equals "test exclusion keeps ${prod_file}" "false" "true"
	else
		assert_equals "test exclusion keeps ${prod_file}" "false" "false"
	fi
done

# --- Idiomatic test-file exclusions hold during a real scan ---
echo "  --- Idiomatic Test Exclusion Scans ---"

idiomatic_dir=$(mktemp -d)
cat >"$idiomatic_dir/FooTests.cs" <<'EOF'
class FooTests { void Run() { ServicePointManager.ServerCertificateValidationCallback = delegate { return true; }; } }
EOF
cat >"$idiomatic_dir/Prod.cs" <<'EOF'
class Prod { void Run() { ServicePointManager.ServerCertificateValidationCallback = delegate { return true; }; } }
EOF
cat >"$idiomatic_dir/FooTest.kt" <<'EOF'
fun run() { SSLContext.getInstance("TLSv1") }
EOF
cat >"$idiomatic_dir/Prod.kt" <<'EOF'
fun run() { SSLContext.getInstance("TLSv1") }
EOF
cat >"$idiomatic_dir/FooTest.php" <<'EOF'
<?php curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
EOF
cat >"$idiomatic_dir/prod.php" <<'EOF'
<?php curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
EOF
cat >"$idiomatic_dir/foo_spec.rb" <<'EOF'
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
EOF
cat >"$idiomatic_dir/prod.rb" <<'EOF'
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
EOF

for idiomatic_lang in csharp kotlin php ruby; do
	FINDINGS=()
	CRITICAL_COUNT=0
	HIGH_COUNT=0
	MEDIUM_COUNT=0
	INFO_COUNT=0
	scan_language "$idiomatic_dir" "$idiomatic_lang" "" ""
	scanned=$(printf '%s\n' "${FINDINGS[@]+"${FINDINGS[@]}"}")
	case "$idiomatic_lang" in
		csharp) prod_name="Prod.cs" test_name="FooTests.cs" ;;
		kotlin) prod_name="Prod.kt" test_name="FooTest.kt" ;;
		php) prod_name="prod.php" test_name="FooTest.php" ;;
		ruby) prod_name="prod.rb" test_name="foo_spec.rb" ;;
	esac
	assert_contains "$idiomatic_lang scan reports the production file" "|$prod_name|" "$scanned"
	if [[ "$scanned" == *"|$test_name|"* ]]; then
		assert_equals "$idiomatic_lang scan skips its test file" "true" "false"
	else
		assert_equals "$idiomatic_lang scan skips its test file" "true" "true"
	fi
done
rm -rf "$idiomatic_dir"

# build_lang_exclude_dirs
assert_contains "build_lang_exclude_dirs nodejs" "node_modules" "$(build_lang_exclude_dirs "nodejs")"
assert_contains "build_lang_exclude_dirs python" "__pycache__" "$(build_lang_exclude_dirs "python")"
assert_equals "build_lang_exclude_dirs unknown returns empty" "" "$(build_lang_exclude_dirs "unknown")"

# build_common_exclude_dirs
common_flags=$(build_common_exclude_dirs "")
assert_contains "build_common_exclude_dirs has vendor" "vendor" "$common_flags"
assert_contains "build_common_exclude_dirs has .git" ".git" "$common_flags"
assert_contains "build_common_exclude_dirs has testdata" "testdata" "$common_flags"

extra_flags=$(build_common_exclude_dirs "custom1,custom2")
assert_contains "build_common_exclude_dirs extra dirs (custom1)" "custom1" "$extra_flags"
assert_contains "build_common_exclude_dirs extra dirs (custom2)" "custom2" "$extra_flags"

# Nested paths cannot be expressed as --exclude-dir; they are post-filtered
nested_flags=$(build_common_exclude_dirs "internal/legacy,fixtures")
if [[ "$nested_flags" == *"internal/legacy"* ]]; then
	assert_equals "build_common_exclude_dirs omits nested entries" "true" "false"
else
	assert_equals "build_common_exclude_dirs omits nested entries" "true" "true"
fi
assert_contains "build_common_exclude_dirs keeps single-segment entries" "--exclude-dir=fixtures" "$nested_flags"

# path_is_in_excluded_dir
if path_is_in_excluded_dir "internal/legacy/a.go" "internal/legacy"; then
	assert_equals "path_is_in_excluded_dir matches nested path" "true" "true"
else
	assert_equals "path_is_in_excluded_dir matches nested path" "true" "false"
fi
if path_is_in_excluded_dir "internal/legacy/a.go" "./internal/legacy/"; then
	assert_equals "path_is_in_excluded_dir normalizes entry" "true" "true"
else
	assert_equals "path_is_in_excluded_dir normalizes entry" "true" "false"
fi
if path_is_in_excluded_dir "other/legacy/a.go" "internal/legacy"; then
	assert_equals "path_is_in_excluded_dir rejects sibling path" "false" "true"
else
	assert_equals "path_is_in_excluded_dir rejects sibling path" "false" "false"
fi
if path_is_in_excluded_dir "internal/legacy/a.go" ""; then
	assert_equals "path_is_in_excluded_dir ignores empty config" "false" "true"
else
	assert_equals "path_is_in_excluded_dir ignores empty config" "false" "false"
fi
if path_is_in_excluded_dir "internal/legacy/a.go" "legacy"; then
	assert_equals "path_is_in_excluded_dir checks single-name components" "true" "true"
else
	assert_equals "path_is_in_excluded_dir checks single-name components" "true" "false"
fi

# file_matches_excluded_dir shares the nested-path behavior (incremental scans)
if file_matches_excluded_dir "go" "internal/legacy/a.go" "internal/legacy"; then
	assert_equals "file_matches_excluded_dir matches nested path" "true" "true"
else
	assert_equals "file_matches_excluded_dir matches nested path" "true" "false"
fi
if file_matches_excluded_dir "go" "other/legacy/a.go" "internal/legacy"; then
	assert_equals "file_matches_excluded_dir rejects sibling path" "false" "true"
else
	assert_equals "file_matches_excluded_dir rejects sibling path" "false" "false"
fi
if file_matches_excluded_dir "ruby" "spec/support/helper.rb" ""; then
	assert_equals "file_matches_excluded_dir skips ruby spec dir" "true" "true"
else
	assert_equals "file_matches_excluded_dir skips ruby spec dir" "true" "false"
fi
if file_matches_excluded_dir "csharp" "spec/support/helper.cs" ""; then
	assert_equals "file_matches_excluded_dir keeps other languages' spec dir" "false" "true"
else
	assert_equals "file_matches_excluded_dir keeps other languages' spec dir" "false" "false"
fi

# Full scan: a nested exclude-dirs entry skips only that path
echo "  --- Nested exclude-dirs Scan Tests ---"
nested_dir=$(mktemp -d)
mkdir -p "$nested_dir/internal/legacy" "$nested_dir/other/legacy"
cat >"$nested_dir/internal/legacy/a.go" <<'GOEOF'
package legacy
import "crypto/tls"
func f() { _ = &tls.Config{InsecureSkipVerify: true} }
GOEOF
cp "$nested_dir/internal/legacy/a.go" "$nested_dir/other/legacy/a.go"

FINDINGS=()
# shellcheck disable=SC2034
CRITICAL_COUNT=0
# shellcheck disable=SC2034
HIGH_COUNT=0
# shellcheck disable=SC2034
MEDIUM_COUNT=0
# shellcheck disable=SC2034
INFO_COUNT=0
scan_language "$nested_dir" "go" "internal/legacy" ""
scanned_files=$(printf '%s\n' "${FINDINGS[@]+"${FINDINGS[@]}"}")
assert_contains "nested exclude-dirs still scans sibling path" "other/legacy/a.go" "$scanned_files"
if [[ "$scanned_files" == *"internal/legacy/a.go"* ]]; then
	assert_equals "nested exclude-dirs skips excluded path" "true" "false"
else
	assert_equals "nested exclude-dirs skips excluded path" "true" "true"
fi
rm -rf "$nested_dir"

# --- Comment-Only Line Tests ---
echo "  --- Comment-Only Line Tests ---"

check_comment() {
	local lang="$1" expected="$2" text="$3" label="$4"
	if is_comment_line "$lang" "$text"; then
		assert_equals "is_comment_line: $label" "$expected" "true"
	else
		assert_equals "is_comment_line: $label" "$expected" "false"
	fi
}

check_comment go true "   // InsecureSkipVerify: true" "Go // with indentation"
check_comment nodejs true "// rejectUnauthorized: false" "Node.js //"
check_comment cpp true "    /* SSL_VERIFY_NONE" "C++ unclosed block comment"
check_comment cpp false "#include <openssl/ssl.h>" "C++ preprocessor is code"
check_comment java true "  // SSLContext" "Java //"
check_comment rust true "// VERIFY_NONE" "Rust //"
check_comment csharp true "// callback" "C# //"
check_comment kotlin true "  // ssl" "Kotlin //"
check_comment php true "// verify false" "PHP //"
check_comment php true "/* verify false" "PHP unclosed block comment"
check_comment php true "# verify false" "PHP hash comment"
check_comment php false '#[Route("/x")]' "PHP attribute is code"
check_comment php false "/* off */ verify_peer => false" "PHP closed block prefix keeps code"
check_comment unknown false "// anything" "Unknown language is not a comment"
check_comment python true "  # verify=False" "Python #"
check_comment ruby true "# VERIFY_NONE" "Ruby #"
check_comment go false "*p = handler" "Go dereference is code"
check_comment go false "/* off */ InsecureSkipVerify: true" "closed block prefix keeps code"
check_comment go false "x := 1 // note" "trailing comment keeps code"

comment_dir=$(mktemp -d)
cat >"$comment_dir/commented.go" <<'EOF'
package main
// InsecureSkipVerify: true
EOF
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0
scan_language "$comment_dir" "go" "" ""
assert_equals "Commented-out Go match yields no findings" "0" "$(get_findings_count)"

rm -f "$comment_dir/commented.go"
cat >"$comment_dir/trailing.go" <<'EOF'
package main
var c = tls.Config{InsecureSkipVerify: true} // why
EOF
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0
scan_language "$comment_dir" "go" "" ""
assert_greater_than "Code with a trailing comment still reports" 0 "$(get_findings_count)"

rm -f "$comment_dir/trailing.go"
cat >"$comment_dir/off.cpp" <<'EOF'
#include <openssl/ssl.h>
/* off */ SSL_CTX_set_verify(ctx, SSL_VERIFY_NONE, NULL);
EOF
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0
scan_language "$comment_dir" "cpp" "" ""
assert_greater_than "Closed block-comment prefix keeps the finding" 0 "$(get_findings_count)"

rm -f "$comment_dir/off.cpp"
cat >"$comment_dir/note.go" <<'EOF'
package main
// BANNEDCIPHER marker
EOF
# shellcheck disable=SC2034  # Consumed and reset by scan_language
EXTRA_PATTERNS=$'org-comment\tHIGH\tComment marker\tMatches a comment on purpose\tBANNEDCIPHER\t'
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0
scan_language "$comment_dir" "go" "" ""
assert_greater_than "Custom pattern still matches a comment line" 0 "$(get_findings_count)"
# shellcheck disable=SC2034  # Written by scan_language, reset for later tests
EXTRA_PATTERNS=""
# shellcheck disable=SC2034  # Written by scan_language, reset for later tests
CUSTOM_PATTERN_IDS=""
rm -rf "$comment_dir"

# --- scan_pattern Column & Truncation Tests ---
echo "  --- Column & Truncation Tests ---"

# Reset state
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
# shellcheck disable=SC2034
MEDIUM_COUNT=0
# shellcheck disable=SC2034
INFO_COUNT=0

# Create temp file with leading whitespace
col_dir=$(mktemp -d)
cat >"$col_dir/ws.go" <<'GOEOF'
package main
    InsecureSkipVerify: true,
GOEOF

source "$ROOT_DIR/patterns/go.sh"
scan_language "$col_dir" "go" "" ""

# Find the finding from ws.go
ws_col=""
for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
	IFS='|' read -r fid _ _ _ ffile _ _ fcol <<<"$finding"
	if [[ "$ffile" == "ws.go" ]] && [[ "$fid" == "insecure-skip-verify" ]]; then
		ws_col="$fcol"
		break
	fi
done
assert_equals "Column offset accounts for leading whitespace" "5" "$ws_col"
rm -rf "$col_dir"

# Test: 200-char truncation
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
# shellcheck disable=SC2034
MEDIUM_COUNT=0
# shellcheck disable=SC2034
INFO_COUNT=0

trunc_dir=$(mktemp -d)
long_line="InsecureSkipVerify: true$(printf '%0.s_' {1..250})"
printf 'package main\n%s\n' "$long_line" >"$trunc_dir/long.go"

scan_language "$trunc_dir" "go" "" ""

trunc_len=""
for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
	IFS='|' read -r fid _ _ _ ffile _ fmatch _ <<<"$finding"
	if [[ "$ffile" == "long.go" ]]; then
		trunc_len="${#fmatch}"
		break
	fi
done
if [[ -n "$trunc_len" ]] && [[ "$trunc_len" -le 200 ]]; then
	assert_equals "Match text truncated to 200 chars" "true" "true"
else
	assert_equals "Match text truncated to 200 chars" "true" "false"
fi
rm -rf "$trunc_dir"

# --- Colon-in-Match Parsing Tests ---
# grep output must be split on the file/line separator grep itself emitted, not
# on the last ":<digits>:" in the line, so a match containing a timestamp keeps
# its real file and line number (and inline suppressions still work).
echo "  --- Colon-in-Match Parsing Tests ---"

FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
# shellcheck disable=SC2034
MEDIUM_COUNT=0
# shellcheck disable=SC2034
INFO_COUNT=0

colon_dir=$(mktemp -d)
cat >"$colon_dir/a.go" <<'GOEOF'
package main

var c = &tls.Config{InsecureSkipVerify: true} // added 12:30:45
GOEOF
cat >"$colon_dir/b.go" <<'GOEOF'
package main

var d = &tls.Config{InsecureSkipVerify: true} // tls-lint:ignore 12:30:45
GOEOF

source "$ROOT_DIR/patterns/go.sh"
scan_language "$colon_dir" "go" "" ""

colon_file=""
colon_line=""
colon_match=""
colon_count=0
for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
	IFS='|' read -r fid _ _ _ ffile fline fmatch _ <<<"$finding"
	if [[ "$fid" == "insecure-skip-verify" ]]; then
		colon_count=$((colon_count + 1))
		colon_file="$ffile"
		colon_line="$fline"
		colon_match="$fmatch"
	fi
done
assert_equals "Colon-in-match reports the real file" "a.go" "$colon_file"
assert_equals "Colon-in-match reports the real line number" "3" "$colon_line"
assert_contains "Colon-in-match keeps the full match text" "12:30:45" "$colon_match"
assert_equals "Inline ignore after a timestamp suppresses the finding" "1" "$colon_count"

# Incremental mode uses a different grep invocation (-H --null) but the same parser
reset_scan_state
CHANGED_FILES_ONLY=true
# shellcheck disable=SC2034  # Used by scanner.sh via scan_language
CHANGED_FILES=("a.go")
scan_language "$colon_dir" "go" "" ""

inc_file=""
inc_line=""
for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
	IFS='|' read -r fid _ _ _ ffile fline _ _ <<<"$finding"
	if [[ "$fid" == "insecure-skip-verify" ]]; then
		inc_file="$ffile"
		inc_line="$fline"
	fi
done
assert_equals "Incremental scan reports the real file for a colon-in-match line" "a.go" "$inc_file"
assert_equals "Incremental scan reports the real line for a colon-in-match line" "3" "$inc_line"
# shellcheck disable=SC2034  # Used by scanner.sh via scan_language
CHANGED_FILES_ONLY=false
# shellcheck disable=SC2034  # Used by scanner.sh via scan_language
LANG_SCAN_FILES=()
unset CHANGED_FILES
rm -rf "$colon_dir"

# --- filter_go_tls_config_noise Tests ---
echo "  --- filter_go_tls_config_noise Tests ---"

FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
# shellcheck disable=SC2034
MEDIUM_COUNT=0
# shellcheck disable=SC2034
INFO_COUNT=0

# Create testdata with TLSSecurityProfile reference alongside hardcoded-tls-config finding
noise_dir=$(mktemp -d)
cat >"$noise_dir/profile.go" <<'GOEOF'
package main

import "crypto/tls"

func configure() *tls.Config {
	return &tls.Config{
		MinVersion: tls.VersionTLS12,
	}
}

func profile() {
	_ = configv1.TLSSecurityProfile{}
}
GOEOF

source "$ROOT_DIR/patterns/go.sh"
scan_language "$noise_dir" "go" "" ""

found_noise=false
for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
	IFS='|' read -r fid _ _ _ ffile _ _ _ <<<"$finding"
	if [[ "$fid" == "hardcoded-tls-config" ]] && [[ "$ffile" == "profile.go" ]]; then
		found_noise=true
		break
	fi
done
assert_equals "filter_go_tls_config_noise removes finding in file with TLSSecurityProfile" "false" "$found_noise"

# Verify FINDING_REGEXES stays in sync with FINDINGS after filtering
assert_equals "FINDING_REGEXES length matches FINDINGS after filter" "${#FINDINGS[@]}" "${#FINDING_REGEXES[@]}"
rm -rf "$noise_dir"

# Test: hardcoded-tls-config kept when no TLSSecurityProfile
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
# shellcheck disable=SC2034
MEDIUM_COUNT=0
# shellcheck disable=SC2034
INFO_COUNT=0

noprofile_dir=$(mktemp -d)
cat >"$noprofile_dir/plain.go" <<'GOEOF'
package main

import "crypto/tls"

func configure() *tls.Config {
	return &tls.Config{
		MinVersion: tls.VersionTLS12,
	}
}
GOEOF

scan_language "$noprofile_dir" "go" "" ""

found_kept=false
for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
	IFS='|' read -r fid _ _ _ _ _ _ _ <<<"$finding"
	if [[ "$fid" == "hardcoded-tls-config" ]]; then
		found_kept=true
		break
	fi
done
assert_equals "hardcoded-tls-config kept without TLSSecurityProfile" "true" "$found_kept"
rm -rf "$noprofile_dir"

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
# shellcheck disable=SC2034  # Used by scanner.sh
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

# Kotlin, C#, PHP, and Ruby secure code
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
# shellcheck disable=SC2034  # Used by scanner.sh
INFO_COUNT=0
fp_dir=$(mktemp -d)
cp "$ROOT_DIR/testdata/kotlin/secure.kt" "$fp_dir/"
source "$ROOT_DIR/patterns/kotlin.sh"
scan_language "$fp_dir" "kotlin" "" ""
assert_equals "Kotlin secure code: no critical findings" "0" "$CRITICAL_COUNT"
assert_equals "Kotlin secure code: no high findings" "0" "$HIGH_COUNT"
rm -rf "$fp_dir"

# C# secure code
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
# shellcheck disable=SC2034  # Used by scanner.sh
INFO_COUNT=0
fp_dir=$(mktemp -d)
cp "$ROOT_DIR/testdata/csharp/secure.cs" "$fp_dir/"
source "$ROOT_DIR/patterns/csharp.sh"
scan_language "$fp_dir" "csharp" "" ""
assert_equals "C# secure code: no critical findings" "0" "$CRITICAL_COUNT"
assert_equals "C# secure code: no high findings" "0" "$HIGH_COUNT"
rm -rf "$fp_dir"

# PHP secure code
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
# shellcheck disable=SC2034  # Used by scanner.sh
INFO_COUNT=0
fp_dir=$(mktemp -d)
cp "$ROOT_DIR/testdata/php/secure.php" "$fp_dir/"
source "$ROOT_DIR/patterns/php.sh"
scan_language "$fp_dir" "php" "" ""
assert_equals "PHP secure code: no critical findings" "0" "$CRITICAL_COUNT"
assert_equals "PHP secure code: no high findings" "0" "$HIGH_COUNT"
rm -rf "$fp_dir"

# Ruby secure code
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
# shellcheck disable=SC2034  # Used by scanner.sh
INFO_COUNT=0
fp_dir=$(mktemp -d)
cp "$ROOT_DIR/testdata/ruby/secure.rb" "$fp_dir/"
source "$ROOT_DIR/patterns/ruby.sh"
scan_language "$fp_dir" "ruby" "" ""
assert_equals "Ruby secure code: no critical findings" "0" "$CRITICAL_COUNT"
assert_equals "Ruby secure code: no high findings" "0" "$HIGH_COUNT"
rm -rf "$fp_dir"
