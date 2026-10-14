#!/usr/bin/env bash
# test_incremental.sh - Incremental Git-diff scan tests

source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/lib/scanner.sh"

echo "  --- Incremental Scan Tests ---"

init_test_repo() {
	git -C "$1" init -q
	git -C "$1" config user.email "tls-lint-tests@example.invalid"
	git -C "$1" config user.name "TLS Lint Tests"
}

# True when every finding in FINDINGS comes from the given file
findings_all_from_file() {
	local expected="$1"
	local finding file
	for finding in "${FINDINGS[@]+${FINDINGS[@]}}"; do
		IFS='|' read -r _ _ _ _ file _ _ _ <<<"$finding"
		[[ "$file" == "$expected" ]] || return 1
	done
	return 0
}

incremental_repo=$(mktemp -d)
# Clean up temp repos even if a command failure aborts this sourced script
trap 'rm -rf "$incremental_repo" "${newlang_repo:-}"' EXIT
init_test_repo "$incremental_repo"

cat >"$incremental_repo/unchanged.go" <<'EOF'
package example

import "crypto/tls"

var unchanged = &tls.Config{InsecureSkipVerify: true}
EOF
cat >"$incremental_repo/changed.go" <<'EOF'
package example

import "crypto/tls"

var changed = &tls.Config{MinVersion: tls.VersionTLS13}
EOF
git -C "$incremental_repo" add .
git -C "$incremental_repo" commit -q -m "base"
base_ref=$(git -C "$incremental_repo" rev-parse HEAD)

cat >"$incremental_repo/changed.go" <<'EOF'
package example

import "crypto/tls"

var changed = &tls.Config{InsecureSkipVerify: true}
EOF
git -C "$incremental_repo" add changed.go
git -C "$incremental_repo" commit -q -m "change"
head_ref=$(git -C "$incremental_repo" rev-parse HEAD)

CHANGED_FILES_ONLY=true
prepare_changed_files "$incremental_repo" "$base_ref" "$head_ref"
assert_equals "Incremental diff selects changed source file" "changed.go" "${CHANGED_FILES[*]}"

reset_scan_state
source "$ROOT_DIR/patterns/go.sh"
scan_language "$incremental_repo" "go" "" ""

assert_greater_than "Incremental scan reports only changed file" 0 "${#FINDINGS[@]}"
assert_true "Incremental scan excludes unchanged insecure file" findings_all_from_file "changed.go"

CHANGED_FILES_ONLY=false
reset_scan_state
scan_language "$incremental_repo" "go" "" ""
full_scan_files=()
for finding in "${FINDINGS[@]+${FINDINGS[@]}}"; do
	IFS='|' read -r _ _ _ _ file _ _ _ <<<"$finding"
	full_scan_files+=("$file")
done
assert_contains "Full scan still includes unchanged file" "unchanged.go" "${full_scan_files[*]}"

CHANGED_FILES_ONLY=true
prepare_changed_files "$incremental_repo" "$head_ref" "$head_ref"
assert_equals "Incremental scan accepts an empty diff" "0" "${#CHANGED_FILES[@]}"

if prepare_changed_files "$incremental_repo" "missing-ref" "$head_ref"; then
	assert_equals "Invalid Git ref is rejected" "false" "true"
else
	assert_equals "Invalid Git ref is rejected" "true" "true"
fi

CHANGED_FILES=(changed_test.go)
files_for_language go ""
assert_equals "Incremental file selection preserves test exclusions" "0" "${#LANG_SCAN_FILES[@]}"

# Newer languages must participate in incremental file selection
assert_true "Incremental selection accepts csharp sources" file_matches_language csharp src/App.cs
assert_true "Incremental selection accepts kotlin sources" file_matches_language kotlin src/App.kt
assert_true "Incremental selection accepts php sources" file_matches_language php src/app.php
assert_true "Incremental selection accepts ruby sources" file_matches_language ruby src/app.rb
assert_false "Incremental selection rejects mismatched extension" file_matches_language ruby src/app.py
assert_false "Incremental selection rejects wrong language" file_matches_language csharp src/app.rb

assert_true "Incremental selection keeps csharp test exclusion" file_matches_test_exclusion csharp src/App_test.cs
assert_true "Incremental selection keeps kotlin test exclusion" file_matches_test_exclusion kotlin src/App_test.kt
assert_true "Incremental selection keeps php test exclusion (suffix)" file_matches_test_exclusion php src/app_test.php
assert_true "Incremental selection keeps php test exclusion (prefix)" file_matches_test_exclusion php src/test_app.php
assert_true "Incremental selection keeps ruby test exclusion (suffix)" file_matches_test_exclusion ruby src/app_test.rb
assert_true "Incremental selection keeps ruby test exclusion (prefix)" file_matches_test_exclusion ruby src/test_app.rb
assert_false "Incremental selection does not exclude ruby sources" file_matches_test_exclusion ruby src/app.rb

CHANGED_FILES=(src/app_test.rb)
files_for_language ruby ""
assert_equals "Incremental file selection preserves ruby test exclusions" "0" "${#LANG_SCAN_FILES[@]}"

# End-to-end: changed ruby/php/csharp/kotlin files produce findings in incremental mode
newlang_repo=$(mktemp -d)
init_test_repo "$newlang_repo"
echo "# baseline" >"$newlang_repo/README.md"
git -C "$newlang_repo" add .
git -C "$newlang_repo" commit -q -m "base"
newlang_base=$(git -C "$newlang_repo" rev-parse HEAD)

mkdir -p "$newlang_repo/src"
cp "$ROOT_DIR/testdata/ruby/insecure.rb" "$newlang_repo/src/insecure.rb"
cp "$ROOT_DIR/testdata/php/insecure.php" "$newlang_repo/src/insecure.php"
cp "$ROOT_DIR/testdata/csharp/insecure.cs" "$newlang_repo/src/insecure.cs"
cp "$ROOT_DIR/testdata/kotlin/insecure.kt" "$newlang_repo/src/insecure.kt"
git -C "$newlang_repo" add .
git -C "$newlang_repo" commit -q -m "add insecure sources"
newlang_head=$(git -C "$newlang_repo" rev-parse HEAD)

prepare_changed_files "$newlang_repo" "$newlang_base" "$newlang_head"
assert_equals "Incremental diff selects all four new-language files" "4" "${#CHANGED_FILES[@]}"

for spec in ruby:rb php:php csharp:cs kotlin:kt; do
	lang="${spec%%:*}"
	expected_file="src/insecure.${spec##*:}"
	reset_scan_state
	scan_language "$newlang_repo" "$lang" "" ""
	assert_greater_than "Incremental scan reports $lang findings" 0 "${#FINDINGS[@]}"
	assert_true "Incremental $lang findings come from the changed file" findings_all_from_file "$expected_file"
done

# shellcheck disable=SC2034 # Consumed by prepare_changed_files in scanner.sh
CHANGED_FILES_ONLY=false
CHANGED_FILES=()
LANG_SCAN_FILES=()

rm -rf "$incremental_repo" "$newlang_repo"
