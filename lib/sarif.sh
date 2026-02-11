#!/usr/bin/env bash
# sarif.sh - SARIF 2.1.0 JSON generator (via jq)

set -euo pipefail

# Generate SARIF 2.1.0 output
generate_sarif() {
	local output_file="$1"

	if ! command -v jq &>/dev/null; then
		log_error "jq is required for SARIF output but not found"
		return 1
	fi

	# Build rules array from unique pattern IDs
	local rules_json="[]"
	local seen_patterns=()

	for finding in "${FINDINGS[@]}"; do
		IFS='|' read -r pattern_id name description _ _ _ <<<"$finding"

		# Skip if already seen
		local already_seen=false
		for seen in "${seen_patterns[@]+"${seen_patterns[@]}"}"; do
			if [[ "$seen" == "$pattern_id" ]]; then
				already_seen=true
				break
			fi
		done
		if $already_seen; then
			continue
		fi
		seen_patterns+=("$pattern_id")

		rules_json=$(echo "$rules_json" | jq \
			--arg id "$pattern_id" \
			--arg name "$name" \
			--arg desc "$description" \
			'. + [{
				id: $id,
				name: $name,
				shortDescription: { text: $name },
				fullDescription: { text: $desc },
				defaultConfiguration: { level: "error" },
				properties: { tags: ["security", "tls"] }
			}]')
	done

	# Build results array
	local results_json="[]"

	for finding in "${FINDINGS[@]}"; do
		IFS='|' read -r pattern_id name description file line_num match_text <<<"$finding"

		# Find rule index
		local rule_index=0
		for i in "${!seen_patterns[@]}"; do
			if [[ "${seen_patterns[$i]}" == "$pattern_id" ]]; then
				rule_index=$i
				break
			fi
		done

		results_json=$(echo "$results_json" | jq \
			--arg id "$pattern_id" \
			--arg msg "$description" \
			--arg file "$file" \
			--argjson line "$line_num" \
			--argjson ruleIdx "$rule_index" \
			--arg snippet "$match_text" \
			'. + [{
				ruleId: $id,
				ruleIndex: $ruleIdx,
				level: "error",
				message: { text: $msg },
				locations: [{
					physicalLocation: {
						artifactLocation: { uri: $file, uriBaseId: "%SRCROOT%" },
						region: { startLine: $line, snippet: { text: $snippet } }
					}
				}]
			}]')
	done

	# Assemble full SARIF document
	local sarif_doc
	sarif_doc=$(jq -n \
		--argjson rules "$rules_json" \
		--argjson results "$results_json" \
		'{
			"$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/main/sarif-2.1/schema/sarif-schema-2.1.0.json",
			version: "2.1.0",
			runs: [{
				tool: {
					driver: {
						name: "tls-config-lint",
						informationUri: "https://github.com/sebrandon1/tls-config-lint",
						version: "2.0.0",
						rules: $rules
					}
				},
				results: $results
			}]
		}')

	echo "$sarif_doc" >"$output_file"
	log_msg "SARIF output written to $output_file"
}
