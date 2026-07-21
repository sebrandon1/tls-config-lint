#!/usr/bin/env bash
# test_report.sh - CSV and JSON report tests

# Source library modules
source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/lib/scanner.sh"
source "$ROOT_DIR/lib/report.sh"

echo "  --- CSV Report Tests ---"

# Set up test findings
FINDINGS=(
	"insecure-skip-verify|CRITICAL|InsecureSkipVerify: true|Disables TLS certificate verification|main.go|42|InsecureSkipVerify: true|5"
	"min-version-tls10|HIGH|MinVersion TLS 1.0|TLS 1.0 has known vulnerabilities|config.go|15|VersionTLS10|3"
)
CRITICAL_COUNT=1
HIGH_COUNT=1
# shellcheck disable=SC2034
MEDIUM_COUNT=0
# shellcheck disable=SC2034
INFO_COUNT=0

# Test: CSV report has header row
csv_file=$(mktemp)
generate_csv_report "$csv_file" 2>/dev/null
csv_output=$(cat "$csv_file")
header=$(head -1 "$csv_file")
assert_equals "CSV has correct header" "pattern_id,severity,name,description,file,line,match,column" "$header"

# Test: CSV report has correct number of data rows
data_lines=$(tail -n +2 "$csv_file" | wc -l | tr -d ' ')
assert_equals "CSV has correct row count" "2" "$data_lines"

# Test: CSV report contains finding data
assert_contains "CSV contains pattern ID" "insecure-skip-verify" "$csv_output"
assert_contains "CSV contains file path" "main.go" "$csv_output"
assert_contains "CSV contains severity" "CRITICAL" "$csv_output"

rm -f "$csv_file"

# Test: CSV escapes fields with commas
FINDINGS=(
	"test-pattern|HIGH|Test, with comma|Description, also commas|file.go|1|match text|1"
)
CRITICAL_COUNT=0
HIGH_COUNT=1

csv_file=$(mktemp)
generate_csv_report "$csv_file" 2>/dev/null
csv_output=$(cat "$csv_file")
assert_contains "CSV quotes fields with commas" '"Test, with comma"' "$csv_output"
assert_contains "CSV quotes description with commas" '"Description, also commas"' "$csv_output"

rm -f "$csv_file"

# Test: CSV escapes fields with double quotes
FINDINGS=(
	'test-pattern|HIGH|Name with "quotes"|Description "here"|file.go|1|match text|1'
)
CRITICAL_COUNT=0
HIGH_COUNT=1

csv_file=$(mktemp)
generate_csv_report "$csv_file" 2>/dev/null
csv_output=$(cat "$csv_file")
assert_contains "CSV doubles internal quotes" '""quotes""' "$csv_output"

rm -f "$csv_file"

# Test: CSV with empty findings produces header only
FINDINGS=()
CRITICAL_COUNT=0
HIGH_COUNT=0

csv_file=$(mktemp)
generate_csv_report "$csv_file" 2>/dev/null
line_count=$(wc -l <"$csv_file" | tr -d ' ')
assert_equals "CSV empty findings has header only" "1" "$line_count"

rm -f "$csv_file"

echo "  --- JSON Report Tests ---"

# Reset findings for JSON tests
FINDINGS=(
	"insecure-skip-verify|CRITICAL|InsecureSkipVerify: true|Disables TLS certificate verification|main.go|42|InsecureSkipVerify: true|5"
	"min-version-tls10|HIGH|MinVersion TLS 1.0|TLS 1.0 has known vulnerabilities|config.go|15|VersionTLS10|3"
)
CRITICAL_COUNT=1
HIGH_COUNT=1
# shellcheck disable=SC2034
MEDIUM_COUNT=0
# shellcheck disable=SC2034
INFO_COUNT=0

# shellcheck disable=SC2034  # Used by generate_json_report
SCAN_PATH="."
# shellcheck disable=SC2034  # Used by generate_json_report
LANGUAGES="go"
# shellcheck disable=SC2034  # Used by generate_json_report
SEVERITY_THRESHOLD="high"

if command -v jq &>/dev/null; then
	json_file=$(mktemp)
	generate_json_report "$json_file" 2>/dev/null

	# Test: JSON is valid
	if jq empty "$json_file" 2>/dev/null; then
		assert_equals "JSON output is valid" "true" "true"
	else
		assert_equals "JSON output is valid" "true" "false"
	fi

	# Test: JSON has metadata
	tool_name=$(jq -r '.metadata.tool' "$json_file")
	assert_equals "JSON metadata has tool name" "tls-config-lint" "$tool_name"

	scan_path=$(jq -r '.metadata.scanPath' "$json_file")
	assert_equals "JSON metadata has scan path" "." "$scan_path"

	languages=$(jq -r '.metadata.languages' "$json_file")
	assert_equals "JSON metadata has languages" "go" "$languages"

	threshold=$(jq -r '.metadata.severityThreshold' "$json_file")
	assert_equals "JSON metadata has threshold" "high" "$threshold"

	version=$(jq -r '.metadata.version' "$json_file")
	assert_equals "JSON metadata has version" "true" "$([[ -n "$version" ]] && echo true || echo false)"

	# Test: JSON has summary counts
	total=$(jq '.summary.total' "$json_file")
	assert_equals "JSON summary total" "2" "$total"

	critical=$(jq '.summary.critical' "$json_file")
	assert_equals "JSON summary critical" "1" "$critical"

	high=$(jq '.summary.high' "$json_file")
	assert_equals "JSON summary high" "1" "$high"

	# Test: JSON has correct findings count
	findings_count=$(jq '.findings | length' "$json_file")
	assert_equals "JSON findings count" "2" "$findings_count"

	# Test: JSON finding has expected fields
	first_pid=$(jq -r '.findings[0].patternId' "$json_file")
	assert_equals "JSON finding has patternId" "insecure-skip-verify" "$first_pid"

	first_sev=$(jq -r '.findings[0].severity' "$json_file")
	assert_equals "JSON finding has severity" "CRITICAL" "$first_sev"

	first_file=$(jq -r '.findings[0].file' "$json_file")
	assert_equals "JSON finding has file" "main.go" "$first_file"

	first_line=$(jq '.findings[0].line' "$json_file")
	assert_equals "JSON finding has line" "42" "$first_line"

	first_col=$(jq '.findings[0].column' "$json_file")
	assert_equals "JSON finding has column" "5" "$first_col"

	first_name=$(jq -r '.findings[0].name' "$json_file")
	assert_equals "JSON finding has name" "InsecureSkipVerify: true" "$first_name"

	first_desc=$(jq -r '.findings[0].description' "$json_file")
	assert_equals "JSON finding has description" "Disables TLS certificate verification" "$first_desc"

	first_match=$(jq -r '.findings[0].match' "$json_file")
	assert_equals "JSON finding has match" "InsecureSkipVerify: true" "$first_match"

	rm -f "$json_file"

	# Test: JSON with empty findings produces valid output
	FINDINGS=()
	CRITICAL_COUNT=0
	HIGH_COUNT=0

	json_file=$(mktemp)
	generate_json_report "$json_file" 2>/dev/null
	empty_count=$(jq '.findings | length' "$json_file")
	assert_equals "JSON empty findings has empty array" "0" "$empty_count"
	empty_total=$(jq '.summary.total' "$json_file")
	assert_equals "JSON empty findings has zero total" "0" "$empty_total"

	rm -f "$json_file"
else
	echo "  (skipping JSON tests — jq not available)"
fi

echo "  --- Report Dispatcher Tests ---"

# Test: generate_report dispatches to CSV
# shellcheck disable=SC2034  # Used by generate_report
FINDINGS=(
	"test-pattern|HIGH|Test|Description|file.go|1|match|1"
)
# shellcheck disable=SC2034  # Used by generate_report
CRITICAL_COUNT=0
# shellcheck disable=SC2034  # Used by generate_report
HIGH_COUNT=1
# shellcheck disable=SC2034
MEDIUM_COUNT=0
# shellcheck disable=SC2034
INFO_COUNT=0

csv_file=$(mktemp --suffix=.csv 2>/dev/null || mktemp).csv
generate_report "$csv_file" 2>/dev/null
header=$(head -1 "$csv_file")
assert_equals "Dispatcher routes .csv to CSV generator" "pattern_id,severity,name,description,file,line,match,column" "$header"
rm -f "$csv_file"

# Test: generate_report dispatches to JSON
if command -v jq &>/dev/null; then
	json_file=$(mktemp --suffix=.json 2>/dev/null || mktemp).json
	generate_report "$json_file" 2>/dev/null
	if jq empty "$json_file" 2>/dev/null; then
		assert_equals "Dispatcher routes .json to JSON generator" "true" "true"
	else
		assert_equals "Dispatcher routes .json to JSON generator" "true" "false"
	fi
	rm -f "$json_file"
fi

# Test: generate_report rejects unsupported extension
if generate_report "/tmp/report.txt" 2>/dev/null; then
	assert_equals "Unsupported extension rejected" "should_fail" "passed"
else
	assert_equals "Unsupported extension rejected" "true" "true"
fi
