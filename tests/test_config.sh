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

# Test: Missing config file returns defaults
parse_config_file "/nonexistent/file.yml"
assert_equals "Missing config returns empty severity" "" "$CFG_SEVERITY_THRESHOLD"
assert_equals "Missing config returns empty languages" "" "$CFG_LANGUAGES"

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

# Cleanup
rm -f "$TEMP_CONFIG"
