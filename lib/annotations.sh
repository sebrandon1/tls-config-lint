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
	local i=0
	for finding in "${FINDINGS[@]}"; do
		IFS='|' read -r pattern_id severity name description file line_num match_text _ <<<"$finding"

		local annotation_type
		annotation_type=$(severity_to_sarif_level "$severity")
		[[ "$annotation_type" == "note" ]] && annotation_type="notice"

		local message="[${severity}] ${name}: ${description}"
		if [[ -n "${DEBUG:-}" ]]; then
			message="${message} | match: ${match_text}"
			local finding_regex="${FINDING_REGEXES[$i]:-}"
			if [[ -n "$finding_regex" ]]; then
				message="${message} | regex: ${finding_regex}"
			fi
		fi

		echo "::${annotation_type} file=${file},line=${line_num},title=TLS Config Lint (${pattern_id})::${message}"
		i=$((i + 1))
	done
}

emit_annotations_cli() {
	echo ""
	echo -e "${COLOR_BOLD}Findings:${COLOR_RESET}"
	echo ""

	local i=0
	for finding in "${FINDINGS[@]}"; do
		IFS='|' read -r pattern_id severity name description file line_num match_text _ <<<"$finding"

		local sev_lower color
		sev_lower=$(normalize_severity "$severity")

		case "$sev_lower" in
			critical | high) color="$COLOR_RED" ;;
			medium) color="$COLOR_YELLOW" ;;
			*) color="$COLOR_BLUE" ;;
		esac

		echo -e "  ${color}[${severity}]${COLOR_RESET} ${file}:${line_num} — ${COLOR_BOLD}${name}${COLOR_RESET}: ${description}"
		if [[ -n "${DEBUG:-}" ]]; then
			echo -e "    ${COLOR_DIM}Match: ${match_text}${COLOR_RESET}"
			local finding_regex="${FINDING_REGEXES[$i]:-}"
			if [[ -n "$finding_regex" ]]; then
				echo -e "    ${COLOR_DIM}Regex: ${finding_regex}${COLOR_RESET}"
			fi
		fi
		i=$((i + 1))
	done
}
