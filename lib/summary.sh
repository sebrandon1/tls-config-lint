#!/usr/bin/env bash
# summary.sh - $GITHUB_STEP_SUMMARY markdown generator

set -euo pipefail

# Generate job summary markdown
generate_summary() {
	local severity_threshold="$1"
	local total
	total=$(get_findings_count)

	# Build summary markdown
	local summary=""

	summary+="## TLS Config Lint Results\n\n"

	if [[ "$total" -eq 0 ]]; then
		summary+="**No TLS configuration issues found.**\n\n"
	else
		summary+="| Severity | Count |\n"
		summary+="|----------|-------|\n"
		if [[ "$CRITICAL_COUNT" -gt 0 ]]; then
			summary+="| :red_circle: Critical | $CRITICAL_COUNT |\n"
		fi
		if [[ "$HIGH_COUNT" -gt 0 ]]; then
			summary+="| :orange_circle: High | $HIGH_COUNT |\n"
		fi
		if [[ "$MEDIUM_COUNT" -gt 0 ]]; then
			summary+="| :yellow_circle: Medium | $MEDIUM_COUNT |\n"
		fi
		if [[ "$INFO_COUNT" -gt 0 ]]; then
			summary+="| :blue_circle: Info | $INFO_COUNT |\n"
		fi
		summary+="\n"
		summary+="**Total findings:** $total | **Threshold:** $severity_threshold\n\n"

		# Findings table
		summary+="### Findings\n\n"
		summary+="| Severity | Pattern | File | Line | Description |\n"
		summary+="|----------|---------|------|------|-------------|\n"

		for finding in "${FINDINGS[@]}"; do
			IFS='|' read -r pattern_id severity name description file line_num match_text <<<"$finding"
			# Escape pipe characters in description for markdown table
			description="${description//|/\\|}"
			summary+="| $severity | $name | \`$file\` | $line_num | $description |\n"
		done

		summary+="\n"
	fi

	# Write to GITHUB_STEP_SUMMARY if available, otherwise stdout
	if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
		echo -e "$summary" >>"$GITHUB_STEP_SUMMARY"
	else
		echo -e "$summary"
	fi
}
