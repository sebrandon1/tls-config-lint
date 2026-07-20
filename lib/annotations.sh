#!/usr/bin/env bash
# annotations.sh - Finding emitter (GitHub annotations or colored terminal output)

set -euo pipefail

# Emit findings as GitHub annotations or colored terminal lines
emit_annotations() {
	if [[ ${#FINDINGS[@]} -eq 0 ]]; then
		return 0
	fi

	if [[ "$CLI_MODE" == "true" ]]; then
		emit_annotations_cli
	else
		emit_annotations_gha
	fi
}

emit_annotations_gha() {
	for finding in "${FINDINGS[@]}"; do
		# shellcheck disable=SC2034  # match_text unused here but needed for field parsing
		IFS='|' read -r pattern_id severity name description file line_num match_text <<<"$finding"

		local annotation_type
		annotation_type=$(severity_to_sarif_level "$severity")
		[[ "$annotation_type" == "note" ]] && annotation_type="notice"

		local message="[${severity}] ${name}: ${description}"

		echo "::${annotation_type} file=${file},line=${line_num},title=TLS Config Lint (${pattern_id})::${message}"
	done
}

emit_annotations_cli() {
	echo ""
	echo -e "${COLOR_BOLD}Findings:${COLOR_RESET}"
	echo ""

	for finding in "${FINDINGS[@]}"; do
		# shellcheck disable=SC2034  # match_text unused here but needed for field parsing
		IFS='|' read -r pattern_id severity name description file line_num match_text <<<"$finding"

		local sev_lower color
		sev_lower=$(normalize_severity "$severity")

		case "$sev_lower" in
			critical | high) color="$COLOR_RED" ;;
			medium) color="$COLOR_YELLOW" ;;
			*) color="$COLOR_BLUE" ;;
		esac

		echo -e "  ${color}[${severity}]${COLOR_RESET} ${file}:${line_num} — ${COLOR_BOLD}${name}${COLOR_RESET}: ${description}"
	done
}
