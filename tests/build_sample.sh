#!/usr/bin/env bash
# Build examples/sample.md with build_epub.sh and check the EPUB:
# MathML present, no leftover "$", the "(1)" equation number, hyphens: none CSS,
# and no formulas left as raw TeX.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$here/.."
work="$(mktemp -d "${TMPDIR:-/tmp}/build_sample.XXXXXX")"
trap 'rm -rf "$work"' EXIT

fail=0
check() { # description, then a command that succeeds when the check passes
  local what="$1"; shift
  if "$@"; then echo "PASS  $what"; else echo "FAIL  $what"; fail=1; fi
}

echo "pandoc: $(pandoc --version | head -1)"
"$root/skills/pdf2epub/build_epub.sh" "$root/examples/sample.md" "$work/sample.epub" \
  2> "$work/build.log"
echo "built: sample.epub ($(wc -c < "$work/sample.epub" | tr -d ' ') bytes)"
if [[ -s "$work/build.log" ]]; then echo "--- build_epub.sh stderr:"; cat "$work/build.log"; echo "---"; fi

mkdir "$work/x"
unzip -q "$work/sample.epub" -d "$work/x"
xhtml=("$work"/x/EPUB/text/*.xhtml)
css=("$work"/x/EPUB/styles/*.css)

# Text of the book: annotations (which hold the TeX source) and tags removed.
perl -0777 -pe 's{<annotation\b.*?</annotation>}{}gs; s{<[^>]+>}{}g' "${xhtml[@]}" > "$work/text.txt"
# Text of the display formulas only, one per line (so prose like "(1) holds" can't match).
perl -0777 -ne 'while (/(<math\b[^>]*display="block".*?<\/math>)/gs) {
  my $m = $1; $m =~ s{<annotation\b.*?</annotation>}{}gs; $m =~ s{<[^>]+>}{}g;
  $m =~ s/\s+//g; print "$m\n" }' "${xhtml[@]}" > "$work/display.txt"

check "no formulas left as raw TeX" \
  bash -c '! grep -q "left as raw TeX" "$1"' _ "$work/build.log"
check "EPUB contains MathML" \
  grep -q '<math' "${xhtml[@]}"
check "no leftover \$ in the book text" \
  bash -c '! grep -q "\\$" "$1"' _ "$work/text.txt"
check "equation number (1) is shown in a display formula" \
  grep -q '(1)$' "$work/display.txt"
check "stylesheet has hyphens: none" \
  grep -Eq 'hyphens:[[:space:]]*none' "${css[@]}"

exit $fail
