#!/usr/bin/env bash
# annotations.sh - GitHub Actions ::error/::warning/::notice emitter

set -euo pipefail

# Emit GitHub Actions annotations for all findings
emit_annotations() {
	if [[ ${#FINDINGS[@]} -eq 0 ]]; then
		return 0
	fi

	for finding in "${FINDINGS[@]}"; do
		# shellcheck disable=SC2034  # match_text unused here but needed for field parsing
		IFS='|' read -r pattern_id severity name description file line_num match_text <<<"$finding"

		local sev_lower
		sev_lower=$(normalize_severity "$severity")

		local annotation_type
		case "$sev_lower" in
			critical | high) annotation_type="error" ;;
			medium) annotation_type="warning" ;;
			info) annotation_type="notice" ;;
			*) annotation_type="notice" ;;
		esac

		local message="[${severity}] ${name}: ${description}"

		echo "::${annotation_type} file=${file},line=${line_num},title=TLS Config Lint (${pattern_id})::${message}"
	done
}
