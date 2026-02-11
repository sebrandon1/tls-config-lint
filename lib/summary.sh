#!/usr/bin/env bash
# summary.sh - $GITHUB_STEP_SUMMARY markdown generator

set -euo pipefail

# Generate job summary markdown
generate_summary() {
	local total
	total=$(get_findings_count)

	# Build summary markdown
	local summary=""

	summary+="## TLS Config Lint Results\n\n"

	if [[ "$total" -eq 0 ]]; then
		summary+=":white_check_mark: **PASS** - No TLS configuration issues found.\n\n"
	else
		summary+=":x: **FAIL** - ${total} finding(s) detected.\n\n"
		summary+="Any hardcoded TLS configuration that does not dynamically inherit from the cluster's centralized \`tlsSecurityProfile\` is a failure.\n\n"

		# Findings table
		summary+="### Findings\n\n"
		summary+="| Pattern | File | Line | Description |\n"
		summary+="|---------|------|------|-------------|\n"

		for finding in "${FINDINGS[@]}"; do
			# shellcheck disable=SC2034  # All fields needed for table row
			IFS='|' read -r pattern_id name description file line_num match_text <<<"$finding"
			# Escape pipe characters in description for markdown table
			description="${description//|/\\|}"
			summary+="| $name | \`$file\` | $line_num | $description |\n"
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
