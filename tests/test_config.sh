#!/usr/bin/env bash
# test_config.sh - Config parser tests

# Source library modules
source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/lib/config.sh"

echo "  --- Config Parser Tests ---"

# Create a temporary config file
TEMP_CONFIG=$(mktemp)
cat >"$TEMP_CONFIG" <<'EOF'
severity-threshold: critical
languages:
  - go
  - python
exclude-dirs:
  - test/fixtures
  - examples/insecure
exclude-patterns:
  - insecure-skip-verify    # Intentional in test helpers
  - verify-false
EOF

# Test: Parse config file
parse_config_file "$TEMP_CONFIG"

assert_equals "Config parses severity-threshold" "critical" "$CFG_SEVERITY_THRESHOLD"
assert_equals "Config parses languages" "go,python" "$CFG_LANGUAGES"
assert_equals "Config parses exclude-dirs" "test/fixtures,examples/insecure" "$CFG_EXCLUDE_DIRS"
assert_equals "Config parses exclude-patterns" "insecure-skip-verify,verify-false" "$CFG_EXCLUDE_PATTERNS"
assert_equals "Config without severity-overrides returns empty" "" "$CFG_SEVERITY_OVERRIDES"

# Test: Parse custom extra-pattern records
TEMP_CUSTOM=$(mktemp)
cat >"$TEMP_CUSTOM" <<'EOF'
extra-patterns:
  - id: org-weak-cipher
    severity: high
    name: Organization banned cipher suite
    description: Uses a cipher banned by policy
    regex: 'TLS_RSA_WITH_AES_128_CBC_SHA'
    languages: [go, java]
EOF
parse_config_file "$TEMP_CUSTOM"
assert_contains "Config parses custom pattern ID" "org-weak-cipher" "$CFG_EXTRA_PATTERNS"
assert_contains "Config parses custom pattern language scope" "go,java" "$CFG_EXTRA_PATTERNS"
rm -f "$TEMP_CUSTOM"

# Test: Parse new-language scopes in both list syntaxes
TEMP_NEWLANG=$(mktemp)
cat >"$TEMP_NEWLANG" <<'EOF'
extra-patterns:
  - id: org-rb-marker
    severity: medium
    name: Ruby marker
    description: Ruby marker found
    regex: 'VERIFY_NONE'
    languages: [ruby, php]
  - id: org-cs-marker
    severity: medium
    name: CSharp marker
    description: CSharp marker found
    regex: 'ServicePointManager'
    languages: csharp, kotlin
EOF
parse_config_file "$TEMP_NEWLANG"
assert_contains "Config parses bracketed new-language scope" "ruby,php" "$CFG_EXTRA_PATTERNS"
assert_contains "Config parses bare new-language scope" "csharp,kotlin" "$CFG_EXTRA_PATTERNS"
rm -f "$TEMP_NEWLANG"

# Test: Inline lists for every list-valued key
TEMP_INLINE=$(mktemp)
cat >"$TEMP_INLINE" <<'EOF'
severity-threshold: high
languages: [go, python]
exclude-dirs: [test/fixtures, examples/insecure]
exclude-patterns: [insecure-skip-verify, verify-false]
exceptions: [insecure-skip-verify:test_helpers.go, min-version-tls10:internal/legacy/]
severity-overrides: [min-version-tls10:critical, hardcoded-tls-config:medium]
EOF
parse_config_file "$TEMP_INLINE"
assert_equals "Inline list languages" "go,python" "$CFG_LANGUAGES"
assert_equals "Inline list exclude-dirs" "test/fixtures,examples/insecure" "$CFG_EXCLUDE_DIRS"
assert_equals "Inline list exclude-patterns" "insecure-skip-verify,verify-false" "$CFG_EXCLUDE_PATTERNS"
assert_equals "Inline list exceptions" "insecure-skip-verify:test_helpers.go,min-version-tls10:internal/legacy/" "$CFG_EXCEPTIONS"
assert_equals "Inline list severity-overrides" "min-version-tls10:critical,hardcoded-tls-config:medium" "$CFG_SEVERITY_OVERRIDES"
rm -f "$TEMP_INLINE"

# Test: '#' inside a quoted value is preserved
TEMP_HASH=$(mktemp)
cat >"$TEMP_HASH" <<'EOF'
exclude-patterns:
  - 'pattern#literal'
extra-patterns:
  - id: org-hash
    severity: high
    name: Hashed
    description: 'banned cipher #3'
    regex: 'TLSv1[.#]'
EOF
parse_config_file "$TEMP_HASH"
assert_equals "Quoted list value keeps '#'" "pattern#literal" "$CFG_EXCLUDE_PATTERNS"
assert_contains "Quoted description keeps '#'" "banned cipher #3" "$CFG_EXTRA_PATTERNS"
assert_contains "Quoted regex keeps '#'" "TLSv1[.#]" "$CFG_EXTRA_PATTERNS"
rm -f "$TEMP_HASH"

# Test: Quoted value followed by a comment stops at the quote
TEMP_HASH_COMMENT=$(mktemp)
cat >"$TEMP_HASH_COMMENT" <<'EOF'
exclude-patterns:
  - 'pattern#literal'    # trailing note
EOF
parse_config_file "$TEMP_HASH_COMMENT"
assert_equals "Quoted value ignores trailing comment" "pattern#literal" "$CFG_EXCLUDE_PATTERNS"
rm -f "$TEMP_HASH_COMMENT"

# Test: Double-quoted '#' is preserved too
TEMP_HASH_DQ=$(mktemp)
cat >"$TEMP_HASH_DQ" <<'EOF'
exclude-patterns: ["pattern#literal"]
EOF
parse_config_file "$TEMP_HASH_DQ"
assert_equals "Double-quoted inline item keeps '#'" "pattern#literal" "$CFG_EXCLUDE_PATTERNS"
rm -f "$TEMP_HASH_DQ"

# Test: Unterminated quote keeps the rest of the value
_strip_result=$(_strip_inline_comment "'unterminated #value")
assert_equals "Unterminated quote keeps value" "unterminated #value" "$_strip_result"
_strip_result=$(_strip_inline_comment "plain #comment")
assert_equals "Unquoted value drops comment" "plain " "$_strip_result"

# Test: Empty inline list and trailing comma are tolerated
TEMP_EMPTY_LIST=$(mktemp)
cat >"$TEMP_EMPTY_LIST" <<'EOF'
languages: []
exclude-dirs: [go,]
EOF
parse_config_file "$TEMP_EMPTY_LIST"
assert_equals "Empty inline list yields empty value" "" "$CFG_LANGUAGES"
assert_equals "Trailing comma does not add an item" "go" "$CFG_EXCLUDE_DIRS"
rm -f "$TEMP_EMPTY_LIST"

# Test: Unknown extra-pattern field under flexible indentation
TEMP_BAD_FIELD=$(mktemp)
cat >"$TEMP_BAD_FIELD" <<'EOF'
extra-patterns:
- id: org-bad-field
  severity: high
  name: Bad field
  description: Has an unknown field
  regex: 'MARKER'
  bogus: value
EOF
parse_config_file "$TEMP_BAD_FIELD"
assert_equals "Unknown extra-pattern field sets error flag" "true" "$CFG_EXTRA_PATTERNS_ERROR"
rm -f "$TEMP_BAD_FIELD"

# Test: Extra-pattern block indented with two spaces
TEMP_TWO_SPACE=$(mktemp)
cat >"$TEMP_TWO_SPACE" <<'EOF'
extra-patterns:
- id: org-two-space
  severity: high
  name: Two space entry
  description: Parsed with two-space indentation
  regex: 'INSECURE_MARKER'
severity-threshold: medium
EOF
parse_config_file "$TEMP_TWO_SPACE"
assert_contains "Two-space extra-pattern parses ID" "org-two-space" "$CFG_EXTRA_PATTERNS"
assert_contains "Two-space extra-pattern parses description" "Parsed with two-space indentation" "$CFG_EXTRA_PATTERNS"
assert_equals "Key after extra-pattern block still parses" "medium" "$CFG_SEVERITY_THRESHOLD"
if [[ "$CFG_EXTRA_PATTERNS_ERROR" == "true" ]]; then
	assert_equals "Two-space extra-pattern is valid" "true" "false"
else
	assert_equals "Two-space extra-pattern is valid" "true" "true"
fi
rm -f "$TEMP_TWO_SPACE"

# Test: Malformed extra-pattern entry sets the error flag
TEMP_BAD_PATTERN=$(mktemp)
cat >"$TEMP_BAD_PATTERN" <<'EOF'
extra-patterns:
  - id: org-missing-regex
    severity: high
    name: Missing regex
    description: No regex field
EOF
parse_config_file "$TEMP_BAD_PATTERN"
assert_equals "Malformed extra-pattern sets error flag" "true" "$CFG_EXTRA_PATTERNS_ERROR"
rm -f "$TEMP_BAD_PATTERN"

# Test: Unknown key produces warning with suggestion
TEMP_UNKNOWN=$(mktemp)
cat >"$TEMP_UNKNOWN" <<'EOF'
sevrity-threshold: high
languages:
  - go
EOF

output=$(parse_config_file "$TEMP_UNKNOWN" 2>&1)
assert_contains "Unknown key warns with suggestion" "did you mean" "$output"
assert_contains "Unknown key suggests correct key" "severity-threshold" "$output"
rm -f "$TEMP_UNKNOWN"

# Test: Completely unknown key lists valid keys
TEMP_BOGUS=$(mktemp)
cat >"$TEMP_BOGUS" <<'EOF'
foobar: true
EOF

output=$(parse_config_file "$TEMP_BOGUS" 2>&1)
assert_contains "Unknown key lists valid keys" "valid keys:" "$output"
rm -f "$TEMP_BOGUS"

# Test: Missing config file returns defaults
parse_config_file "/nonexistent/file.yml"
assert_equals "Missing config returns empty severity" "" "$CFG_SEVERITY_THRESHOLD"
assert_equals "Missing config returns empty languages" "" "$CFG_LANGUAGES"
assert_equals "Missing config returns empty severity-overrides" "" "$CFG_SEVERITY_OVERRIDES"

# Test: Merge config with inputs
export INPUT_SEVERITY_THRESHOLD=""
export INPUT_LANGUAGES=""
export INPUT_EXCLUDE_DIRS="my-dir"
export INPUT_EXCLUDE_PATTERNS=""
export INPUT_CONFIG_FILE="$TEMP_CONFIG"
export INPUT_SCAN_PATH="."
export INPUT_FAIL_ON_FINDINGS="true"
export INPUT_SARIF_OUTPUT=""

merge_config

# Omitted inputs fall back to config
assert_equals "Merge uses config severity when input is omitted" "critical" "$SEVERITY_THRESHOLD"
assert_equals "Merge uses config languages when input is omitted" "go,python" "$LANGUAGES"
# Exclude dirs should be union of input + config
assert_contains "Merge unions exclude dirs" "my-dir" "$EXCLUDE_DIRS"
assert_contains "Merge unions exclude dirs" "test/fixtures" "$EXCLUDE_DIRS"

# Test: Input overrides config, including values equal to the documented default
export INPUT_SEVERITY_THRESHOLD="medium"
export INPUT_LANGUAGES="cpp"

merge_config

assert_equals "Merge uses input severity when provided" "medium" "$SEVERITY_THRESHOLD"
assert_equals "Merge uses input languages when provided" "cpp" "$LANGUAGES"

export INPUT_SEVERITY_THRESHOLD="high"
export INPUT_LANGUAGES="auto"

merge_config

assert_equals "Explicit default severity beats config" "high" "$SEVERITY_THRESHOLD"
assert_equals "Explicit auto languages beats config" "auto" "$LANGUAGES"

# Test: Explicit false beats a config that enables incremental scanning
TEMP_INCREMENTAL=$(mktemp)
cat >"$TEMP_INCREMENTAL" <<'EOF'
changed-files-only: true
base-ref: origin/develop
head-ref: release
EOF
export INPUT_CHANGED_FILES_ONLY="false"
export INPUT_BASE_REF=""
export INPUT_HEAD_REF=""
export INPUT_CONFIG_FILE="$TEMP_INCREMENTAL"

merge_config

assert_equals "Explicit false beats config changed-files-only" "false" "$CHANGED_FILES_ONLY"
assert_equals "Omitted base-ref takes config value" "origin/develop" "$BASE_REF"
assert_equals "Omitted head-ref takes config value" "release" "$HEAD_REF"

export INPUT_CHANGED_FILES_ONLY="true"
export INPUT_BASE_REF="origin/main"
export INPUT_HEAD_REF="HEAD"

merge_config

assert_equals "Explicit true beats config changed-files-only" "true" "$CHANGED_FILES_ONLY"
assert_equals "Explicit base-ref beats config" "origin/main" "$BASE_REF"
assert_equals "Explicit head-ref beats config" "HEAD" "$HEAD_REF"
rm -f "$TEMP_INCREMENTAL"

# Test: Neither input nor config yields the documented defaults
TEMP_EMPTY=$(mktemp)
export INPUT_SEVERITY_THRESHOLD=""
export INPUT_LANGUAGES=""
export INPUT_CHANGED_FILES_ONLY=""
export INPUT_BASE_REF=""
export INPUT_HEAD_REF=""
export INPUT_CONFIG_FILE="$TEMP_EMPTY"

merge_config

assert_equals "Default severity is high" "high" "$SEVERITY_THRESHOLD"
assert_equals "Default languages is auto" "auto" "$LANGUAGES"
assert_equals "Default changed-files-only is false" "false" "$CHANGED_FILES_ONLY"
assert_equals "Default base-ref is HEAD~1" "HEAD~1" "$BASE_REF"
assert_equals "Default head-ref is HEAD" "HEAD" "$HEAD_REF"
rm -f "$TEMP_EMPTY"

# Restore inputs for subsequent tests
export INPUT_SEVERITY_THRESHOLD="high"
export INPUT_LANGUAGES="auto"
export INPUT_CHANGED_FILES_ONLY="false"
export INPUT_BASE_REF="HEAD~1"
export INPUT_HEAD_REF="HEAD"

# Test: Parse exceptions from config
TEMP_EXCEPTIONS=$(mktemp)
cat >"$TEMP_EXCEPTIONS" <<'EOF'
severity-threshold: high
exceptions:
  - insecure-skip-verify:test_helpers.go
  - min-version-tls10:internal/legacy/
EOF

parse_config_file "$TEMP_EXCEPTIONS"
assert_contains "Config parses exceptions (file entry)" "insecure-skip-verify:test_helpers.go" "$CFG_EXCEPTIONS"
assert_contains "Config parses exceptions (dir entry)" "min-version-tls10:internal/legacy/" "$CFG_EXCEPTIONS"

# Test: Exceptions are exported via merge_config
export INPUT_SEVERITY_THRESHOLD="high"
export INPUT_LANGUAGES="auto"
export INPUT_EXCLUDE_DIRS=""
export INPUT_EXCLUDE_PATTERNS=""
export INPUT_CONFIG_FILE="$TEMP_EXCEPTIONS"
export INPUT_SCAN_PATH="."
export INPUT_FAIL_ON_FINDINGS="true"
export INPUT_SARIF_OUTPUT=""

merge_config
assert_contains "Merge exports exceptions" "insecure-skip-verify:test_helpers.go" "$EXCEPTIONS"

rm -f "$TEMP_EXCEPTIONS"

# Test: Parse severity-overrides from config
TEMP_OVERRIDES=$(mktemp)
cat >"$TEMP_OVERRIDES" <<'EOF'
severity-threshold: high
severity-overrides:
  - hardcoded-tls-config:high
  - prefer-server-cipher-suites:info
EOF

parse_config_file "$TEMP_OVERRIDES"
assert_contains "Config parses severity-overrides (first entry)" "hardcoded-tls-config:high" "$CFG_SEVERITY_OVERRIDES"
assert_contains "Config parses severity-overrides (second entry)" "prefer-server-cipher-suites:info" "$CFG_SEVERITY_OVERRIDES"

# Test: Severity overrides are exported via merge_config
export INPUT_SEVERITY_THRESHOLD="high"
export INPUT_LANGUAGES="auto"
export INPUT_EXCLUDE_DIRS=""
export INPUT_EXCLUDE_PATTERNS=""
export INPUT_CONFIG_FILE="$TEMP_OVERRIDES"
export INPUT_SCAN_PATH="."
export INPUT_FAIL_ON_FINDINGS="true"
export INPUT_SARIF_OUTPUT=""

merge_config
assert_contains "Merge exports severity overrides" "hardcoded-tls-config:high" "$SEVERITY_OVERRIDES"

rm -f "$TEMP_OVERRIDES"

# Test: Exclude-patterns merge (union of input + config)
TEMP_MERGE_PAT=$(mktemp)
cat >"$TEMP_MERGE_PAT" <<'EOF'
exclude-patterns:
  - verify-false
  - cert-none
EOF

export INPUT_SEVERITY_THRESHOLD="high"
export INPUT_LANGUAGES="auto"
export INPUT_EXCLUDE_DIRS=""
export INPUT_EXCLUDE_PATTERNS="insecure-skip-verify"
export INPUT_CONFIG_FILE="$TEMP_MERGE_PAT"
export INPUT_SCAN_PATH="."
export INPUT_FAIL_ON_FINDINGS="true"
export INPUT_SARIF_OUTPUT=""

merge_config
assert_contains "Merge unions exclude-patterns (input)" "insecure-skip-verify" "$EXCLUDE_PATTERNS"
assert_contains "Merge unions exclude-patterns (config)" "verify-false" "$EXCLUDE_PATTERNS"
assert_contains "Merge unions exclude-patterns (config 2)" "cert-none" "$EXCLUDE_PATTERNS"
rm -f "$TEMP_MERGE_PAT"

# Test: Inline key:value syntax in config
TEMP_INLINE=$(mktemp)
cat >"$TEMP_INLINE" <<'EOF'
severity-threshold: medium
languages: go,rust
exclude-dirs: vendor,tmp
EOF

parse_config_file "$TEMP_INLINE"
assert_equals "Inline syntax parses severity-threshold" "medium" "$CFG_SEVERITY_THRESHOLD"
assert_contains "Inline syntax parses languages (go)" "go" "$CFG_LANGUAGES"
assert_contains "Inline syntax parses languages (rust)" "rust" "$CFG_LANGUAGES"
assert_contains "Inline syntax parses exclude-dirs (vendor)" "vendor" "$CFG_EXCLUDE_DIRS"
assert_contains "Inline syntax parses exclude-dirs (tmp)" "tmp" "$CFG_EXCLUDE_DIRS"
rm -f "$TEMP_INLINE"

# Test: REPORT_OUTPUT pass-through via merge_config
TEMP_RPT=$(mktemp)
cat >"$TEMP_RPT" <<'EOF'
severity-threshold: high
EOF

export INPUT_SEVERITY_THRESHOLD="high"
export INPUT_LANGUAGES="auto"
export INPUT_EXCLUDE_DIRS=""
export INPUT_EXCLUDE_PATTERNS=""
export INPUT_CONFIG_FILE="$TEMP_RPT"
export INPUT_SCAN_PATH="."
export INPUT_FAIL_ON_FINDINGS="true"
export INPUT_SARIF_OUTPUT=""
export INPUT_REPORT_OUTPUT="report.csv"

merge_config
assert_equals "Merge exports REPORT_OUTPUT" "report.csv" "$REPORT_OUTPUT"
unset INPUT_REPORT_OUTPUT
rm -f "$TEMP_RPT"

# Cleanup
rm -f "$TEMP_CONFIG"

echo "  --- Config Validation Tests ---"

# Helper to run validate_config in a subshell with given values
# shellcheck disable=SC2034  # Variables are used by validate_config
run_validate() {
	(
		SEVERITY_THRESHOLD="$1"
		LANGUAGES="$2"
		FAIL_ON_FINDINGS="$3"
		SCAN_PATH="$4"
		SEVERITY_OVERRIDES="${5:-}"
		REPORT_OUTPUT="${6:-}"
		validate_config 2>/dev/null
	)
}

# Test: Invalid severity threshold is rejected
if run_validate "invalid" "auto" "true" "."; then
	assert_equals "Invalid severity threshold rejected" "should_fail" "passed"
else
	assert_equals "Invalid severity threshold rejected" "true" "true"
fi

# Test: Invalid language is rejected
if run_validate "high" "go,invalid_lang" "true" "."; then
	assert_equals "Invalid language rejected" "should_fail" "passed"
else
	assert_equals "Invalid language rejected" "true" "true"
fi

# Test: Invalid fail-on-findings is rejected
if run_validate "high" "auto" "maybe" "."; then
	assert_equals "Invalid fail-on-findings rejected" "should_fail" "passed"
else
	assert_equals "Invalid fail-on-findings rejected" "true" "true"
fi

# Test: Invalid scan path is rejected
if run_validate "high" "auto" "true" "/nonexistent/path"; then
	assert_equals "Invalid scan path rejected" "should_fail" "passed"
else
	assert_equals "Invalid scan path rejected" "true" "true"
fi

# Test: Invalid severity override is rejected
if run_validate "high" "auto" "true" "." "insecure-skip-verify:crtical"; then
	assert_equals "Invalid severity override rejected" "should_fail" "passed"
else
	assert_equals "Invalid severity override rejected" "true" "true"
fi

# Test: Valid severity override passes validation
if run_validate "high" "auto" "true" "." "insecure-skip-verify:medium"; then
	assert_equals "Valid severity override passes validation" "true" "true"
else
	assert_equals "Valid severity override passes validation" "true" "false"
fi

# Test: Invalid report-output extension is rejected
if run_validate "high" "auto" "true" "." "" "report.txt"; then
	assert_equals "Invalid report-output extension rejected" "should_fail" "passed"
else
	assert_equals "Invalid report-output extension rejected" "true" "true"
fi

# Test: Valid report-output extensions pass validation
if run_validate "high" "auto" "true" "." "" "report.json"; then
	assert_equals "Valid .json report-output passes" "true" "true"
else
	assert_equals "Valid .json report-output passes" "true" "false"
fi

if run_validate "high" "auto" "true" "." "" "report.csv"; then
	assert_equals "Valid .csv report-output passes" "true" "true"
else
	assert_equals "Valid .csv report-output passes" "true" "false"
fi

# Test: Newer languages are valid extra-pattern scopes
# shellcheck disable=SC2034  # Consumed by validate_config in config.sh
EXTRA_PATTERNS=$'org-rb\tHIGH\tRuby marker\tRuby marker found\tVERIFY_NONE\truby'
if run_validate "high" "auto" "true" "."; then
	assert_equals "Extra pattern ruby scope validates" "true" "true"
else
	assert_equals "Extra pattern ruby scope validates" "true" "false"
fi

# shellcheck disable=SC2034  # Consumed by validate_config in config.sh
EXTRA_PATTERNS=$'org-multi\tHIGH\tMulti marker\tMulti marker found\tVERIFY_NONE\tphp,csharp,kotlin'
if run_validate "high" "auto" "true" "."; then
	assert_equals "Extra pattern php/csharp/kotlin scopes validate" "true" "true"
else
	assert_equals "Extra pattern php/csharp/kotlin scopes validate" "true" "false"
fi

# Test: Genuinely unsupported languages are still rejected
# shellcheck disable=SC2034  # Consumed by validate_config in config.sh
EXTRA_PATTERNS=$'org-bad\tHIGH\tBad marker\tBad marker found\tVERIFY_NONE\tsmalltalk'
if run_validate "high" "auto" "true" "."; then
	assert_equals "Extra pattern unknown language still rejected" "should_fail" "passed"
else
	assert_equals "Extra pattern unknown language still rejected" "true" "true"
fi
# shellcheck disable=SC2034  # Consumed by validate_config in config.sh
EXTRA_PATTERNS=""

# Test: Valid config passes validation
if run_validate "high" "go,python" "true" "."; then
	assert_equals "Valid config passes validation" "true" "true"
else
	assert_equals "Valid config passes validation" "true" "false"
fi
