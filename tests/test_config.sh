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

# Test: Missing config file returns defaults
parse_config_file "/nonexistent/file.yml"
assert_equals "Missing config returns empty severity" "" "$CFG_SEVERITY_THRESHOLD"
assert_equals "Missing config returns empty languages" "" "$CFG_LANGUAGES"
assert_equals "Missing config returns empty severity-overrides" "" "$CFG_SEVERITY_OVERRIDES"

# Test: Merge config with inputs
export INPUT_SEVERITY_THRESHOLD="high"
export INPUT_LANGUAGES="auto"
export INPUT_EXCLUDE_DIRS="my-dir"
export INPUT_EXCLUDE_PATTERNS=""
export INPUT_CONFIG_FILE="$TEMP_CONFIG"
export INPUT_SCAN_PATH="."
export INPUT_FAIL_ON_FINDINGS="true"
export INPUT_SARIF_OUTPUT=""

merge_config

# Input severity is "high" (default), so config's "critical" should win
assert_equals "Merge uses config severity when input is default" "critical" "$SEVERITY_THRESHOLD"
# Input languages is "auto" (default), so config's list should win
assert_equals "Merge uses config languages when input is auto" "go,python" "$LANGUAGES"
# Exclude dirs should be union of input + config
assert_contains "Merge unions exclude dirs" "my-dir" "$EXCLUDE_DIRS"
assert_contains "Merge unions exclude dirs" "test/fixtures" "$EXCLUDE_DIRS"

# Test: Input overrides config when non-default
export INPUT_SEVERITY_THRESHOLD="medium"
export INPUT_LANGUAGES="cpp"

merge_config

assert_equals "Merge uses input severity when non-default" "medium" "$SEVERITY_THRESHOLD"
assert_equals "Merge uses input languages when non-auto" "cpp" "$LANGUAGES"

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

# Test: Valid config passes validation
if run_validate "high" "go,python" "true" "."; then
	assert_equals "Valid config passes validation" "true" "true"
else
	assert_equals "Valid config passes validation" "true" "false"
fi
