#!/usr/bin/env bash
# test_docs.sh - Documentation consistency tests

echo "  --- Documentation Consistency Tests ---"

# Assert against the extracted anchor inventory, not the full document, so a
# failure prints the anchor list instead of the whole patterns.md.
anchors_blob="$(grep -o '<a id="[^"]*"></a>' "$ROOT_DIR/docs/patterns.md")"

# Test: Every registered pattern has a remediation anchor in docs/patterns.md.
# Anchors keep the language prefix because pattern IDs repeat across languages.
total_patterns=0
for pattern_file in "$ROOT_DIR"/patterns/*.sh; do
	# shellcheck source=/dev/null
	source "$pattern_file"
	lang="${pattern_file##*/}"
	lang="${lang%.sh}"
	array_name="$(echo "$lang" | tr '[:lower:]' '[:upper:]')_PATTERNS"
	eval "entries=(\"\${${array_name}[@]}\")"
	# shellcheck disable=SC2154  # Assigned by the eval above
	for entry in "${entries[@]}"; do
		pattern_id="${entry%%|*}"
		total_patterns=$((total_patterns + 1))
		assert_contains "Docs anchor for ${lang}/${pattern_id}" "<a id=\"${lang}-${pattern_id}\"></a>" "$anchors_blob"
	done
done

# Test: Documented pattern counts match the registry total
readme_content=$(cat "$ROOT_DIR/README.md")
readme_count=$(printf '%s\n' "$readme_content" | sed -n 's/.*\*\*\([0-9]*\) TLS Anti-Patterns\*\*.*/\1/p')
assert_equals "README feature count matches registry" "$total_patterns" "$readme_count"

readme_guide_count=$(printf '%s\n' "$readme_content" | sed -n 's/.*All \([0-9]*\) patterns.*/\1/p')
assert_equals "README guide count matches registry" "$total_patterns" "$readme_guide_count"

docs_intro_count=$(sed -n 's/.*detects \([0-9]*\) TLS anti-patterns.*/\1/p' "$ROOT_DIR/docs/patterns.md")
assert_equals "Patterns doc intro count matches registry" "$total_patterns" "$docs_intro_count"
