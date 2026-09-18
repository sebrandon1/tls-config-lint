#!/usr/bin/env bash
# test_custom_patterns.sh - User-defined pattern tests

source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/lib/scanner.sh"

echo "  --- Custom Pattern Tests ---"

custom_dir=$(mktemp -d)
cat >"$custom_dir/example.go" <<'EOF'
package example

const cipher = "TLS_RSA_WITH_AES_128_CBC_SHA"
EOF
cat >"$custom_dir/example.java" <<'EOF'
class Example { String cipher = "TLS_RSA_WITH_AES_128_CBC_SHA"; }
EOF

EXTRA_PATTERNS=$'org-weak-cipher\tHIGH\tOrganization banned cipher suite\tUses a cipher banned by policy\tTLS_RSA_WITH_AES_128_CBC_SHA\tgo,java'
CUSTOM_PATTERN_IDS=""
# shellcheck disable=SC2034  # Used by scan_pattern via scanner.sh
EXCLUDE_PATTERNS="weak-cipher-3des"
EXCEPTIONS=""
SEVERITY_OVERRIDES=""
EXCLUDED_PATTERNS_USED=""

FINDINGS=()
FINDING_REGEXES=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0
scan_language "$custom_dir" "go" "" "$EXCLUDE_PATTERNS"
assert_equals "Scoped custom pattern finds Go match" "1" "${#FINDINGS[@]}"
assert_equals "Scoped custom pattern uses stable ID" "true" "$(printf '%s\n' "${FINDINGS[@]}" | grep -q '^org-weak-cipher|' && echo true || echo false)"

FINDINGS=()
FINDING_REGEXES=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0
scan_language "$custom_dir" "java" "" ""
assert_equals "Scoped custom pattern finds Java match" "1" "${#FINDINGS[@]}"

EXTRA_PATTERNS=$'org-unscoped\tINFO\tOrganization marker\tOrganization marker found\tTLS_RSA_WITH_AES_128_CBC_SHA\t'
CUSTOM_PATTERN_IDS=""
FINDINGS=()
FINDING_REGEXES=()
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
INFO_COUNT=0
scan_language "$custom_dir" "go" "" "org-unscoped"
assert_equals "Excluded custom pattern produces no custom finding" "false" "$(printf '%s\n' "${FINDINGS[@]}" | grep -q '^org-unscoped|' && echo true || echo false)"
assert_contains "Custom pattern exclusion is audited" "org-unscoped" "$EXCLUDED_PATTERNS_USED"

rm -rf "$custom_dir"
