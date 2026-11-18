#!/usr/bin/env bash
# summary.sh - Job summary generator (GitHub markdown or plain terminal)

set -euo pipefail

# Build comma-separated language breakdown from FINDINGS array.
# Outputs nothing if findings span only one language.
build_language_breakdown() {
	local go_count=0 py_count=0 js_count=0 cpp_count=0 java_count=0 rust_count=0
	local rb_count=0 php_count=0 cs_count=0 kt_count=0
	local lang_types=0
	for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
		IFS='|' read -r _ _ _ _ file _ _ _ <<<"$finding"
		case "$file" in
			*.go) go_count=$((go_count + 1)) ;;
			*.py) py_count=$((py_count + 1)) ;;
			*.js | *.ts | *.mjs | *.mts) js_count=$((js_count + 1)) ;;
			*.cpp | *.cc | *.cxx | *.hpp | *.h) cpp_count=$((cpp_count + 1)) ;;
			*.java) java_count=$((java_count + 1)) ;;
			*.rs) rust_count=$((rust_count + 1)) ;;
			*.rb) rb_count=$((rb_count + 1)) ;;
			*.php) php_count=$((php_count + 1)) ;;
			*.cs) cs_count=$((cs_count + 1)) ;;
			*.kt) kt_count=$((kt_count + 1)) ;;
		esac
	done
	# Labels in output order; each spec is "<count variable>:<label>".
	local spec_list="go_count:Go cpp_count:C++ java_count:Java js_count:Node.js py_count:Python rust_count:Rust rb_count:Ruby php_count:PHP cs_count:C# kt_count:Kotlin"
	local spec var
	for spec in $spec_list; do
		var=${spec%%:*}
		[[ "${!var}" -gt 0 ]] && lang_types=$((lang_types + 1))
	done
	[[ "$lang_types" -gt 1 ]] || return 0
	local langs=""
	local first=true
	for spec in $spec_list; do
		var=${spec%%:*}
		[[ "${!var}" -gt 0 ]] || continue
		$first || langs+=", "
		langs+="${spec#*:} (${!var})"
		first=false
	done
	echo "$langs"
}

# Check if any exclusions are configured
has_exclusion_config() {
	[[ -n "${EXCLUDE_PATTERNS:-}" ]] || [[ -n "${EXCEPTIONS:-}" ]] || [[ "$INLINE_SUPPRESSION_COUNT" -gt 0 ]]
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

	if has_exclusion_config; then
		echo ""
		echo -e "  ${COLOR_BOLD}Exclusion audit:${COLOR_RESET}"
		if [[ -n "${EXCLUDE_PATTERNS:-}" ]]; then
			IFS=',' read -ra pats <<<"$EXCLUDE_PATTERNS"
			for pat in "${pats[@]}"; do
				pat="${pat// /}"
				if in_csv_list "$pat" "${EXCLUDED_PATTERNS_USED:-}"; then
					echo "    $pat — suppressed (skipped during scan)"
				else
					echo -e "    $pat — ${COLOR_YELLOW}unused${COLOR_RESET} (no matches to suppress)"
				fi
			done
		fi
		if [[ -n "${EXCEPTIONS:-}" ]]; then
			IFS=',' read -ra excs <<<"$EXCEPTIONS"
			for exc in "${excs[@]}"; do
				exc="${exc// /}"
				local exc_pattern="${exc%%:*}"
				local exc_path="${exc#*:}"
				local matched=false
				IFS=',' read -ra used_entries <<<"${EXCEPTIONS_USED:-}"
				for used in "${used_entries[@]+"${used_entries[@]}"}"; do
					local used_pat="${used%%:*}"
					local used_file="${used#*:}"
					if [[ "$used_pat" != "$exc_pattern" ]]; then
						continue
					fi
					# Directory prefix match or exact/glob match
					if [[ "$exc_path" == */ ]] && [[ "$used_file" == "$exc_path"* ]]; then
						matched=true
						break
					fi
					# shellcheck disable=SC2053
					if [[ "$used_file" == $exc_path ]]; then
						matched=true
						break
					fi
				done
				if $matched; then
					echo "    $exc — suppressed findings"
				else
					echo -e "    $exc — ${COLOR_YELLOW}unused${COLOR_RESET} (no matches to suppress)"
				fi
			done
		fi
		if [[ "$INLINE_SUPPRESSION_COUNT" -gt 0 ]]; then
			echo "    Inline suppressions: $INLINE_SUPPRESSION_COUNT finding(s) suppressed"
		fi
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
		summary+="| Severity | Pattern | File | Line | Description | Docs |\n"
		summary+="|----------|---------|------|------|-------------|------|\n"

		for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
			# shellcheck disable=SC2034  # All fields needed for table row
			IFS='|' read -r pattern_id severity name description file line_num match_text _ <<<"$finding"
			# Escape pipe characters in description for markdown table
			description="${description//|/\\|}"
			local docs_url
			docs_url=$(pattern_docs_url "$pattern_id" "$file")
			summary+="| $severity | $name | \`$file\` | $line_num | $description | [View]($docs_url) |\n"
		done

		summary+="\n"
	fi

	if has_exclusion_config; then
		summary+="### Exclusion Audit\n\n"
		summary+="| Type | Entry | Status |\n"
		summary+="|------|-------|--------|\n"
		if [[ -n "${EXCLUDE_PATTERNS:-}" ]]; then
			IFS=',' read -ra pats <<<"$EXCLUDE_PATTERNS"
			for pat in "${pats[@]}"; do
				pat="${pat// /}"
				if in_csv_list "$pat" "${EXCLUDED_PATTERNS_USED:-}"; then
					summary+="| Excluded pattern | \`$pat\` | :white_check_mark: Suppressed |\n"
				else
					summary+="| Excluded pattern | \`$pat\` | :warning: Unused |\n"
				fi
			done
		fi
		if [[ -n "${EXCEPTIONS:-}" ]]; then
			IFS=',' read -ra excs <<<"$EXCEPTIONS"
			for exc in "${excs[@]}"; do
				exc="${exc// /}"
				local exc_pattern="${exc%%:*}"
				local exc_path="${exc#*:}"
				local matched=false
				IFS=',' read -ra used_entries <<<"${EXCEPTIONS_USED:-}"
				for used in "${used_entries[@]+"${used_entries[@]}"}"; do
					local used_pat="${used%%:*}"
					local used_file="${used#*:}"
					if [[ "$used_pat" != "$exc_pattern" ]]; then
						continue
					fi
					if [[ "$exc_path" == */ ]] && [[ "$used_file" == "$exc_path"* ]]; then
						matched=true
						break
					fi
					# shellcheck disable=SC2053
					if [[ "$used_file" == $exc_path ]]; then
						matched=true
						break
					fi
				done
				if $matched; then
					summary+="| Exception | \`$exc\` | :white_check_mark: Suppressed |\n"
				else
					summary+="| Exception | \`$exc\` | :warning: Unused |\n"
				fi
			done
		fi
		if [[ "$INLINE_SUPPRESSION_COUNT" -gt 0 ]]; then
			summary+="| Inline suppression | — | $INLINE_SUPPRESSION_COUNT finding(s) suppressed |\n"
		fi
		summary+="\n"
	fi

	# Write to GITHUB_STEP_SUMMARY if available, otherwise stdout
	if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
		echo -e "$summary" >>"$GITHUB_STEP_SUMMARY"
	else
		echo -e "$summary"
	fi
}
