#!/usr/bin/env bash
# baseline.sh - Filter findings already present in a SARIF baseline

set -euo pipefail

# Entries are stored as tab-separated: rule ID, normalized file, line.
BASELINE_ENTRIES=()
# Parallel to BASELINE_ENTRIES: "true" once an entry has suppressed a finding.
BASELINE_USED=()
BASELINE_SUPPRESSED_COUNT=0
BASELINE_LINE_PROXIMITY=3

normalize_baseline_file() {
	local uri="$1"
	local scan_abs="$2"

	uri="${uri#file://}"
	uri="${uri#%SRCROOT%/}"
	uri="${uri#./}"
	if [[ "$uri" == "$scan_abs/"* ]]; then
		uri="${uri#"$scan_abs"/}"
	fi
	echo "$uri"
}

load_baseline() {
	local baseline_file="$1"
	local scan_path="$2"
	local scan_abs entries_file id uri line normalized

	if [[ ! -r "$baseline_file" ]]; then
		log_error "Baseline file is not readable: '$baseline_file'"
		return 1
	fi
	if ! scan_abs=$(cd "$scan_path" && pwd); then
		log_error "Cannot resolve scan path for baseline comparison: '$scan_path'"
		return 1
	fi

	if ! jq -e '
		def valid_result:
			(type == "object") and
			((.ruleId | type) == "string") and
			((.locations | type) == "array") and
			(.locations | length > 0) and
			((.locations[0].physicalLocation.artifactLocation.uri | type) == "string") and
			((.locations[0].physicalLocation.region.startLine | type) == "number") and
			((.locations[0].physicalLocation.artifactLocation.uri | contains("\t") | not)) and
			((.locations[0].physicalLocation.artifactLocation.uri | contains("\n") | not));
		type == "object" and
		.version == "2.1.0" and
		(.runs | type) == "array" and
		all(.runs[]; (.results | type) == "array" and all(.results[]; valid_result))
	' "$baseline_file" >/dev/null 2>&1; then
		log_error "Invalid SARIF baseline: '$baseline_file' (expected SARIF 2.1.0 results with rule IDs, files, and lines)"
		return 1
	fi

	entries_file=$(mktemp)
	if ! jq -r '.runs[] | .results[] | [.ruleId, .locations[0].physicalLocation.artifactLocation.uri, (.locations[0].physicalLocation.region.startLine | tostring)] | @tsv' "$baseline_file" >"$entries_file"; then
		rm -f "$entries_file"
		log_error "Unable to read SARIF baseline: '$baseline_file'"
		return 1
	fi

	BASELINE_ENTRIES=()
	BASELINE_USED=()
	while IFS=$'\t' read -r id uri line; do
		[[ -z "$id" ]] && continue
		normalized=$(normalize_baseline_file "$uri" "$scan_abs")
		BASELINE_ENTRIES+=("$id"$'\t'"$normalized"$'\t'"$line")
	done <"$entries_file"
	rm -f "$entries_file"
	log_msg "Loaded ${#BASELINE_ENTRIES[@]} baseline finding(s) from $baseline_file"
}

baseline_has_finding() {
	local pattern_id="$1"
	local file="$2"
	local line_num="$3"
	local entry baseline_id baseline_file baseline_line distance

	for entry in "${BASELINE_ENTRIES[@]+${BASELINE_ENTRIES[@]}}"; do
		IFS=$'\t' read -r baseline_id baseline_file baseline_line <<<"$entry"
		if [[ "$baseline_id" != "$pattern_id" || "$baseline_file" != "$file" ]]; then
			continue
		fi
		distance=$((line_num - baseline_line))
		if ((distance < 0)); then
			distance=$((-distance))
		fi
		if ((distance <= BASELINE_LINE_PROXIMITY)); then
			return 0
		fi
	done
	return 1
}

# Claim one unused baseline entry for a finding, marking it consumed.
# mode "exact" requires the same line; "near" takes the nearest entry within
# BASELINE_LINE_PROXIMITY. Must run in the current shell so BASELINE_USED sticks.
baseline_claim_finding() {
	local pattern_id="$1"
	local file="$2"
	local line_num="$3"
	local mode="$4"
	local idx baseline_id baseline_file baseline_line distance
	local best_idx=-1 best_distance=0

	if [[ ${#BASELINE_ENTRIES[@]} -eq 0 ]]; then
		return 1
	fi

	for idx in "${!BASELINE_ENTRIES[@]}"; do
		if [[ "${BASELINE_USED[$idx]:-false}" == "true" ]]; then
			continue
		fi
		IFS=$'\t' read -r baseline_id baseline_file baseline_line <<<"${BASELINE_ENTRIES[$idx]}"
		if [[ "$baseline_id" != "$pattern_id" || "$baseline_file" != "$file" ]]; then
			continue
		fi
		distance=$((line_num - baseline_line))
		if ((distance < 0)); then
			distance=$((-distance))
		fi
		if [[ "$mode" == "exact" ]]; then
			if ((distance == 0)); then
				BASELINE_USED[$idx]=true
				return 0
			fi
		elif ((distance <= BASELINE_LINE_PROXIMITY)); then
			if ((best_idx < 0)) || ((distance < best_distance)); then
				best_idx=$idx
				best_distance=$distance
			fi
		fi
	done

	if ((best_idx >= 0)); then
		BASELINE_USED[$best_idx]=true
		return 0
	fi
	return 1
}

filter_baseline_findings() {
	local finding pattern_id severity file line_num
	local kept_findings=()
	local kept_regexes=()
	local claimed=()
	local i=0
	BASELINE_SUPPRESSED_COUNT=0
	BASELINE_USED=()

	# Pass 1: exact line matches claim their own entry, so a nearby new finding
	# cannot borrow an entry that belongs to an exact match.
	for finding in "${FINDINGS[@]+${FINDINGS[@]}}"; do
		IFS='|' read -r pattern_id severity _ _ file line_num _ _ <<<"$finding"
		if baseline_claim_finding "$pattern_id" "$file" "$line_num" exact; then
			claimed[$i]=true
		fi
		i=$((i + 1))
	done

	# Pass 2: remaining findings claim the nearest unused entry within tolerance.
	i=0
	for finding in "${FINDINGS[@]+${FINDINGS[@]}}"; do
		if [[ "${claimed[$i]:-false}" != "true" ]]; then
			IFS='|' read -r pattern_id severity _ _ file line_num _ _ <<<"$finding"
			if baseline_claim_finding "$pattern_id" "$file" "$line_num" near; then
				claimed[$i]=true
			fi
		fi
		i=$((i + 1))
	done

	# Each baseline entry suppresses at most one finding, and counters move once.
	i=0
	for finding in "${FINDINGS[@]+${FINDINGS[@]}}"; do
		if [[ "${claimed[$i]:-false}" == "true" ]]; then
			IFS='|' read -r _ severity _ _ _ _ _ _ <<<"$finding"
			BASELINE_SUPPRESSED_COUNT=$((BASELINE_SUPPRESSED_COUNT + 1))
			case "$(normalize_severity "$severity")" in
				critical) CRITICAL_COUNT=$((CRITICAL_COUNT - 1)) ;;
				high) HIGH_COUNT=$((HIGH_COUNT - 1)) ;;
				medium) MEDIUM_COUNT=$((MEDIUM_COUNT - 1)) ;;
				info) INFO_COUNT=$((INFO_COUNT - 1)) ;;
			esac
		else
			kept_findings+=("$finding")
			kept_regexes+=("${FINDING_REGEXES[$i]}")
		fi
		i=$((i + 1))
	done

	FINDINGS=("${kept_findings[@]+${kept_findings[@]}}")
	FINDING_REGEXES=("${kept_regexes[@]+${kept_regexes[@]}}")
	log_msg "Baseline comparison suppressed $BASELINE_SUPPRESSED_COUNT finding(s) within ${BASELINE_LINE_PROXIMITY} line(s)"
}
