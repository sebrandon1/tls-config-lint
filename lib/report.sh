#!/usr/bin/env bash
# report.sh - CSV and JSON report generators

set -euo pipefail

csv_escape() {
	local value="$1"
	if [[ "$value" == *","* ]] || [[ "$value" == *'"'* ]] || [[ "$value" == *$'\n'* ]]; then
		value="${value//\"/\"\"}"
		echo "\"$value\""
	else
		echo "$value"
	fi
}

generate_csv_report() {
	local output_file="$1"

	{
		echo "pattern_id,severity,name,description,file,line,match,column"

		for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
			IFS='|' read -r pattern_id severity name description file line_num match_text col <<<"$finding"
			printf '%s,%s,%s,%s,%s,%s,%s,%s\n' \
				"$(csv_escape "$pattern_id")" \
				"$(csv_escape "$severity")" \
				"$(csv_escape "$name")" \
				"$(csv_escape "$description")" \
				"$(csv_escape "$file")" \
				"$line_num" \
				"$(csv_escape "$match_text")" \
				"${col:-1}"
		done
	} >"$output_file"

	log_msg "CSV report written to $output_file"
}

generate_json_report() {
	local output_file="$1"

	if ! command -v jq &>/dev/null; then
		log_error "jq is required for JSON report output but not found"
		return 1
	fi

	local tool_version
	tool_version=$(get_tool_version)

	local total
	total=$(get_findings_count)

	# Write NUL-delimited records to a file and pass it with --rawfile: a single
	# jq invocation, and no argument can grow past the OS limit on a large scan.
	local temp_dir records_file
	temp_dir=$(mktemp -d)
	records_file="$temp_dir/findings"
	: >"$records_file"

	local finding pattern_id severity name description file line_num match_text col
	for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
		IFS='|' read -r pattern_id severity name description file line_num match_text col <<<"$finding"
		printf '%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\000' \
			"$pattern_id" "$severity" "$name" "$description" "$file" "$line_num" "$match_text" "${col:-1}" \
			>>"$records_file"
	done

	local report
	if ! report=$(jq -n \
		--rawfile finding_records "$records_file" \
		--arg version "$tool_version" \
		--arg scanPath "${SCAN_PATH:-.}" \
		--arg languages "${LANGUAGES:-auto}" \
		--arg threshold "${SEVERITY_THRESHOLD:-high}" \
		--argjson total "$total" \
		--argjson critical "$CRITICAL_COUNT" \
		--argjson high "$HIGH_COUNT" \
		--argjson medium "$MEDIUM_COUNT" \
		--argjson info "$INFO_COUNT" \
		'
		def records:
			split("\u0000")
			| map(select(length > 0) | split("\u001f"));

		($finding_records | records) as $finding_data
		| {
			metadata: {
				tool: "tls-config-lint",
				version: $version,
				scanPath: $scanPath,
				languages: $languages,
				severityThreshold: $threshold
			},
			summary: {
				total: $total,
				critical: $critical,
				high: $high,
				medium: $medium,
				info: $info
			},
			findings: [
				$finding_data[] | {
					patternId: .[0],
					severity: .[1],
					name: .[2],
					description: .[3],
					file: .[4],
					line: (.[5] | tonumber),
					match: .[6],
					column: (.[7] | tonumber)
				}
			]
		}'); then
		rm -rf "$temp_dir"
		log_error "Failed to generate JSON report"
		return 1
	fi
	rm -rf "$temp_dir"

	echo "$report" >"$output_file"
	log_msg "JSON report written to $output_file"
}

generate_report() {
	local output_file="$1"

	case "$output_file" in
		*.json)
			generate_json_report "$output_file"
			;;
		*.csv)
			generate_csv_report "$output_file"
			;;
		*)
			log_error "Unsupported report format: '$output_file' (use .json or .csv extension)"
			return 1
			;;
	esac
}
