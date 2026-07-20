#!/usr/bin/env bash
# summary.sh - Job summary generator (GitHub markdown or plain terminal)

set -euo pipefail

# Build comma-separated language breakdown from FINDINGS array.
# Outputs nothing if findings span only one language.
build_language_breakdown() {
	local go_count=0 py_count=0 js_count=0 cpp_count=0 java_count=0 rust_count=0
	local lang_types=0
	for finding in "${FINDINGS[@]}"; do
		IFS='|' read -r _ _ _ _ file _ _ <<<"$finding"
		case "$file" in
			*.go) go_count=$((go_count + 1)) ;;
			*.py) py_count=$((py_count + 1)) ;;
			*.js | *.ts | *.mjs | *.mts) js_count=$((js_count + 1)) ;;
			*.cpp | *.cc | *.hpp | *.h) cpp_count=$((cpp_count + 1)) ;;
			*.java) java_count=$((java_count + 1)) ;;
			*.rs) rust_count=$((rust_count + 1)) ;;
		esac
	done
	for c in $go_count $py_count $js_count $cpp_count $java_count $rust_count; do
		[[ "$c" -gt 0 ]] && lang_types=$((lang_types + 1))
	done
	if [[ "$lang_types" -gt 1 ]]; then
		local langs=""
		local first=true
		[[ "$go_count" -gt 0 ]] && {
			$first || langs+=", "
			langs+="Go ($go_count)"
			first=false
		}
		[[ "$cpp_count" -gt 0 ]] && {
			$first || langs+=", "
			langs+="C++ ($cpp_count)"
			first=false
		}
		[[ "$java_count" -gt 0 ]] && {
			$first || langs+=", "
			langs+="Java ($java_count)"
			first=false
		}
		[[ "$js_count" -gt 0 ]] && {
			$first || langs+=", "
			langs+="Node.js ($js_count)"
			first=false
		}
		[[ "$py_count" -gt 0 ]] && {
			$first || langs+=", "
			langs+="Python ($py_count)"
			first=false
		}
		[[ "$rust_count" -gt 0 ]] && {
			$first || langs+=", "
			langs+="Rust ($rust_count)"
			first=false
		}
		echo "$langs"
	fi
}

# Generate job summary
generate_summary() {
	if [[ "$CLI_MODE" == "true" ]]; then
		generate_summary_cli "$@"
	else
		generate_summary_gha "$@"
	fi
}

# CLI mode: colored plain-text summary to stdout
generate_summary_cli() {
	local severity_threshold="$1"
	local total
	total=$(get_findings_count)

	echo ""
	echo -e "${COLOR_BOLD}TLS Config Lint Results${COLOR_RESET}"
	echo ""

	if [[ -n "${CONFIG_FILE_USED:-}" ]]; then
		echo "  Config: $CONFIG_FILE_USED"
	fi

	if [[ "$total" -eq 0 ]]; then
		echo -e "  ${COLOR_BOLD}No TLS configuration issues found.${COLOR_RESET}"
		echo ""
		return
	fi

	# Severity counts
	[[ "$CRITICAL_COUNT" -gt 0 ]] && echo -e "  ${COLOR_RED}Critical:${COLOR_RESET} $CRITICAL_COUNT"
	[[ "$HIGH_COUNT" -gt 0 ]] && echo -e "  ${COLOR_RED}High:${COLOR_RESET}     $HIGH_COUNT"
	[[ "$MEDIUM_COUNT" -gt 0 ]] && echo -e "  ${COLOR_YELLOW}Medium:${COLOR_RESET}   $MEDIUM_COUNT"
	[[ "$INFO_COUNT" -gt 0 ]] && echo -e "  ${COLOR_BLUE}Info:${COLOR_RESET}     $INFO_COUNT"
	echo ""
	echo "  Total: $total | Threshold: $severity_threshold"

	local breakdown
	breakdown=$(build_language_breakdown)
	if [[ -n "$breakdown" ]]; then
		echo "  By language: $breakdown"
	fi
	echo ""
}

# GitHub Actions mode: markdown summary to $GITHUB_STEP_SUMMARY or stdout
generate_summary_gha() {
	local severity_threshold="$1"
	local total
	total=$(get_findings_count)

	local summary=""

	summary+="## TLS Config Lint Results\n\n"

	if [[ -n "${CONFIG_FILE_USED:-}" ]]; then
		summary+="> Using config: \`$CONFIG_FILE_USED\`\n\n"
	fi

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

		local breakdown
		breakdown=$(build_language_breakdown)
		if [[ -n "$breakdown" ]]; then
			summary+="**By language:** $breakdown\n\n"
		fi

		# Findings table
		summary+="### Findings\n\n"
		summary+="| Severity | Pattern | File | Line | Description |\n"
		summary+="|----------|---------|------|------|-------------|\n"

		for finding in "${FINDINGS[@]}"; do
			# shellcheck disable=SC2034  # All fields needed for table row
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
