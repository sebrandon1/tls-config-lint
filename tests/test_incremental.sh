#!/usr/bin/env bash
# test_incremental.sh - Incremental Git-diff scan tests

source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/lib/scanner.sh"

echo "  --- Incremental Scan Tests ---"

incremental_repo=$(mktemp -d)
git -C "$incremental_repo" init -q
git -C "$incremental_repo" config user.email "tls-lint-tests@example.invalid"
git -C "$incremental_repo" config user.name "TLS Lint Tests"

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

FINDINGS=()
FINDING_REGEXES=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0
EXCEPTIONS=""
SEVERITY_OVERRIDES=""
source "$ROOT_DIR/patterns/go.sh"
scan_language "$incremental_repo" "go" "" ""

assert_equals "Incremental scan reports only changed file" "true" "$([[ ${#FINDINGS[@]} -gt 0 ]] && printf true || printf false)"
only_changed=true
for finding in "${FINDINGS[@]+${FINDINGS[@]}}"; do
	IFS='|' read -r _ _ _ _ file _ _ _ <<<"$finding"
	if [[ "$file" != "changed.go" ]]; then
		only_changed=false
	fi
done
assert_equals "Incremental scan excludes unchanged insecure file" "true" "$only_changed"

CHANGED_FILES_ONLY=false
FINDINGS=()
FINDING_REGEXES=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0
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

CHANGED_FILES_ONLY=false
CHANGED_FILES=()
LANG_SCAN_FILES=()

rm -rf "$incremental_repo"
