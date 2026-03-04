#!/usr/bin/env bash
# test_integration.sh - Integration tests for full entrypoint pipeline

echo "  --- Integration Tests ---"

# Helper: run entrypoint in a subshell with controlled environment
# Usage: run_entrypoint exit_code_var [ENV_VAR=value ...]
run_entrypoint() {
	local __exit_var="$1"
	shift

	local tmpdir
	tmpdir=$(mktemp -d)
	local output_file="$tmpdir/github_output"
	local summary_file="$tmpdir/step_summary"
	touch "$output_file" "$summary_file"

	local exit_code=0
	env -i PATH="$PATH" HOME="$HOME" TERM="${TERM:-dumb}" \
		GITHUB_OUTPUT="$output_file" \
		GITHUB_STEP_SUMMARY="$summary_file" \
		"$@" \
		bash "$ROOT_DIR/entrypoint.sh" >/dev/null 2>&1 || exit_code=$?

	# Export temp paths for assertions
	LAST_TMPDIR="$tmpdir"
	LAST_OUTPUT_FILE="$output_file"
	LAST_SUMMARY_FILE="$summary_file"

	eval "$__exit_var=$exit_code"
}

# Helper: cleanup temp dir
cleanup_entrypoint() {
	if [[ -n "${LAST_TMPDIR:-}" ]]; then
		rm -rf "$LAST_TMPDIR"
		unset LAST_TMPDIR LAST_OUTPUT_FILE LAST_SUMMARY_FILE
	fi
}

# Helper: extract a key's value from GITHUB_OUTPUT
get_output_value() {
	grep "^$1=" "$LAST_OUTPUT_FILE" | cut -d= -f2
}

# --- Test 1: Full scan with all languages detected ---
rc=0 # initialized here; set by run_entrypoint via eval
run_entrypoint rc \
	INPUT_SCAN_PATH="$ROOT_DIR/testdata" \
	INPUT_FAIL_ON_FINDINGS="false" \
	INPUT_CONFIG_FILE="/dev/null"

assert_equals "Integration: full scan exits 0 with fail_on_findings=false" "0" "$rc"

# Verify outputs were written
output_content=$(cat "$LAST_OUTPUT_FILE")
assert_contains "Integration: output contains findings-count" "findings-count=" "$output_content"
assert_contains "Integration: output contains critical-count" "critical-count=" "$output_content"

# Verify summary was generated
summary_content=$(cat "$LAST_SUMMARY_FILE")
assert_contains "Integration: summary contains TLS header" "TLS" "$summary_content"

cleanup_entrypoint

# --- Test 2: Single language scan (Go) ---
run_entrypoint rc \
	INPUT_SCAN_PATH="$ROOT_DIR/testdata/go" \
	INPUT_LANGUAGES="go" \
	INPUT_FAIL_ON_FINDINGS="false" \
	INPUT_CONFIG_FILE="/dev/null"

assert_equals "Integration: Go-only scan exits 0" "0" "$rc"

output_content=$(cat "$LAST_OUTPUT_FILE")
assert_contains "Integration: Go scan has findings" "findings-count=" "$output_content"
assert_greater_than "Integration: Go scan finds patterns" 0 "$(get_output_value findings-count)"

cleanup_entrypoint

# --- Test 3: fail-on-findings=true with critical findings exits 1 ---
run_entrypoint rc \
	INPUT_SCAN_PATH="$ROOT_DIR/testdata" \
	INPUT_SEVERITY_THRESHOLD="critical" \
	INPUT_FAIL_ON_FINDINGS="true" \
	INPUT_CONFIG_FILE="/dev/null"

assert_equals "Integration: fail-on-findings=true exits 1 when criticals found" "1" "$rc"
cleanup_entrypoint

# --- Test 4: fail-on-findings=false always exits 0 ---
run_entrypoint rc \
	INPUT_SCAN_PATH="$ROOT_DIR/testdata" \
	INPUT_SEVERITY_THRESHOLD="critical" \
	INPUT_FAIL_ON_FINDINGS="false" \
	INPUT_CONFIG_FILE="/dev/null"

assert_equals "Integration: fail-on-findings=false exits 0 regardless" "0" "$rc"
cleanup_entrypoint

# --- Test 5: Config file integration ---
config_tmpdir=$(mktemp -d)
cat >"$config_tmpdir/config.yml" <<'YAML'
severity-threshold: medium
languages:
  - go
YAML

run_entrypoint rc \
	INPUT_SCAN_PATH="$ROOT_DIR/testdata/go" \
	INPUT_FAIL_ON_FINDINGS="false" \
	INPUT_CONFIG_FILE="$config_tmpdir/config.yml"

assert_equals "Integration: config file scan exits 0" "0" "$rc"
assert_greater_than "Integration: config file scan finds patterns" 0 "$(get_output_value findings-count)"

cleanup_entrypoint
rm -rf "$config_tmpdir"

# --- Test 6: Pattern exclusion via input ---
run_entrypoint rc \
	INPUT_SCAN_PATH="$ROOT_DIR/testdata/go" \
	INPUT_LANGUAGES="go" \
	INPUT_EXCLUDE_PATTERNS="insecure-skip-verify" \
	INPUT_FAIL_ON_FINDINGS="false" \
	INPUT_CONFIG_FILE="/dev/null"

assert_equals "Integration: pattern exclusion scan exits 0" "0" "$rc"

# The excluded pattern should not appear in summary
summary_content=$(cat "$LAST_SUMMARY_FILE")
assert_equals "Integration: excluded pattern not in summary" "false" \
	"$([[ "$summary_content" == *"insecure-skip-verify"* ]] && echo "true" || echo "false")"

cleanup_entrypoint

# --- Test 7: SARIF output generation ---
sarif_tmpdir=$(mktemp -d)
sarif_file="$sarif_tmpdir/results.sarif"

run_entrypoint rc \
	INPUT_SCAN_PATH="$ROOT_DIR/testdata/go" \
	INPUT_LANGUAGES="go" \
	INPUT_FAIL_ON_FINDINGS="false" \
	INPUT_SARIF_OUTPUT="$sarif_file" \
	INPUT_CONFIG_FILE="/dev/null"

# SARIF generation requires jq; if jq is not available, entrypoint fails
if command -v jq >/dev/null 2>&1; then
	assert_equals "Integration: SARIF scan exits 0" "0" "$rc"

	sarif_valid="false"
	if jq empty "$sarif_file" 2>/dev/null; then
		sarif_valid="true"
	fi
	assert_equals "Integration: SARIF file is valid JSON" "true" "$sarif_valid"

	has_schema=$(jq 'has("$schema")' "$sarif_file" 2>/dev/null)
	assert_equals "Integration: SARIF has schema field" "true" "$has_schema"

	sarif_has_runs=$(jq -r '.runs | length' "$sarif_file" 2>/dev/null)
	assert_greater_than "Integration: SARIF has runs" 0 "$sarif_has_runs"

	# Verify SARIF path is in GITHUB_OUTPUT
	output_content=$(cat "$LAST_OUTPUT_FILE")
	assert_contains "Integration: sarif-file in output" "sarif-file=" "$output_content"
else
	# Without jq, SARIF generation should fail with exit code 2
	assert_equals "Integration: SARIF fails without jq (exit 2)" "2" "$rc"
fi

cleanup_entrypoint
rm -rf "$sarif_tmpdir"

# --- Test 8: Invalid scan path ---
run_entrypoint rc \
	INPUT_SCAN_PATH="/nonexistent/path/does/not/exist" \
	INPUT_FAIL_ON_FINDINGS="false" \
	INPUT_CONFIG_FILE="/dev/null"

assert_equals "Integration: invalid scan path exits 2 (config error)" "2" "$rc"
cleanup_entrypoint

# --- Test 9: Invalid severity threshold ---
run_entrypoint rc \
	INPUT_SCAN_PATH="$ROOT_DIR/testdata" \
	INPUT_SEVERITY_THRESHOLD="bogus" \
	INPUT_FAIL_ON_FINDINGS="false" \
	INPUT_CONFIG_FILE="/dev/null"

assert_equals "Integration: invalid severity threshold exits 2 (config error)" "2" "$rc"
cleanup_entrypoint

# --- Test 10: Invalid language ---
run_entrypoint rc \
	INPUT_SCAN_PATH="$ROOT_DIR/testdata" \
	INPUT_LANGUAGES="cobol" \
	INPUT_FAIL_ON_FINDINGS="false" \
	INPUT_CONFIG_FILE="/dev/null"

assert_equals "Integration: invalid language exits 2 (config error)" "2" "$rc"
cleanup_entrypoint

# --- Test 11: No languages detected (empty directory) ---
empty_tmpdir=$(mktemp -d)

run_entrypoint rc \
	INPUT_SCAN_PATH="$empty_tmpdir" \
	INPUT_FAIL_ON_FINDINGS="false" \
	INPUT_CONFIG_FILE="/dev/null"

assert_equals "Integration: empty dir exits 0 gracefully" "0" "$rc"
cleanup_entrypoint
rm -rf "$empty_tmpdir"

# --- Test 12: Multiple languages scan ---
run_entrypoint rc \
	INPUT_SCAN_PATH="$ROOT_DIR/testdata" \
	INPUT_LANGUAGES="go,python" \
	INPUT_FAIL_ON_FINDINGS="false" \
	INPUT_CONFIG_FILE="/dev/null"

assert_equals "Integration: multi-language scan exits 0" "0" "$rc"
assert_greater_than "Integration: multi-language scan finds patterns" 10 "$(get_output_value findings-count)"

cleanup_entrypoint
