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

	local findings_json="[]"
	for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
		IFS='|' read -r pattern_id severity name description file line_num match_text col <<<"$finding"
		findings_json=$(echo "$findings_json" | jq \
			--arg pid "$pattern_id" \
			--arg sev "$severity" \
			--arg name "$name" \
			--arg desc "$description" \
			--arg file "$file" \
			--argjson line "$line_num" \
			--arg match "$match_text" \
			--argjson col "${col:-1}" \
			'. + [{
				patternId: $pid,
				severity: $sev,
				name: $name,
				description: $desc,
				file: $file,
				line: $line,
				match: $match,
				column: $col
			}]')
	done

	local report
	report=$(jq -n \
		--arg version "$tool_version" \
		--arg scanPath "${SCAN_PATH:-.}" \
		--arg languages "${LANGUAGES:-auto}" \
		--arg threshold "${SEVERITY_THRESHOLD:-high}" \
		--argjson total "$total" \
		--argjson critical "$CRITICAL_COUNT" \
		--argjson high "$HIGH_COUNT" \
		--argjson medium "$MEDIUM_COUNT" \
		--argjson info "$INFO_COUNT" \
		--argjson findings "$findings_json" \
		'{
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
			findings: $findings
		}')

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
