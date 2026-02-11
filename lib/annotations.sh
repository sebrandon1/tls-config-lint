#!/usr/bin/env bash
# annotations.sh - GitHub Actions ::error emitter

set -euo pipefail

# Emit GitHub Actions annotations for all findings
emit_annotations() {
	if [[ ${#FINDINGS[@]} -eq 0 ]]; then
		return 0
	fi

	for finding in "${FINDINGS[@]}"; do
		# shellcheck disable=SC2034  # match_text unused here but needed for field parsing
		IFS='|' read -r pattern_id name description file line_num match_text <<<"$finding"

		local message="[FAIL] ${name}: ${description}"

		echo "::error file=${file},line=${line_num},title=TLS Config Lint (${pattern_id})::${message}"
	done
}
