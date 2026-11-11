#!/usr/bin/env bash
# Check the LaTeX in skills/pdf2epub/symbols.md against pandoc.
#
# - Every recommended entry (a backticked span in the "LaTeX" column of every
#   table outside "Avoid") must convert to MathML with no "Could not convert".
# - Every "Don't write" entry in the "Avoid" table must either fail to convert,
#   or produce different MathML from its partner in the "Write instead" column
#   (the entry at the same position in that cell). An entry with no backticked
#   partner must fail to convert.
#
# "…" placeholders are replaced by "x" before testing.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
symbols="${1:-$here/../skills/pdf2epub/symbols.md}"
[[ -f "$symbols" ]] || { echo "check_symbols: no such file: $symbols" >&2; exit 1; }

# Emit tab-separated lines: "ok<TAB>latex" or "avoid<TAB>latex<TAB>partner".
extract() {
  perl -CSD -ne '
    if (/^##\s+(.*)/) { $avoid = ($1 =~ /^Avoid\b/); next }
    next unless /^\|/;
    next if /^\|\s*-/;                        # separator row
    my @cells = split /(?<!\\)\|/, $_;        # split on unescaped |
    shift @cells;                             # text before the first |
    my @spans = map { [ /`([^`]+)`/g ] } @cells;
    if ($avoid) {
      my @bad = @{ $spans[0] }; my @good = @{ $spans[1] };
      next unless @bad;
      for my $i (0 .. $#bad) {
        my $partner = $i <= $#good ? $good[$i] : "";
        print "avoid\t$bad[$i]\t$partner\n";
      }
    } else {
      print "ok\t$_\n" for @{ $spans[1] };    # column 2 only, not Notes
    }
  ' "$symbols"
}

# Run one formula through pandoc. Sets $warn (stderr) and $mathml (semantics only).
convert() {
  local tex="${1//…/x}"
  local tmp; tmp="$(mktemp "${TMPDIR:-/tmp}/check_symbols.XXXXXX")"
  mathml="$(printf '%s\n' "\$$tex\$" | pandoc -f markdown -t html --math-method=mathml 2>"$tmp")"
  warn="$(cat "$tmp")"; rm -f "$tmp"
  mathml="$(printf '%s' "$mathml" | tr -d '\n' | perl -pe 's{<annotation\b.*?</annotation>}{}g')"
}

pass=0; fail=0
report() { # status latex detail
  if [[ "$1" == PASS ]]; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
  printf '%-4s  %-40s  %s\n' "$1" "$2" "$3"
}

echo "pandoc: $(pandoc --version | head -1)"
echo "glossary: $symbols"
echo

entries="$(extract)"
[[ -n "$entries" ]] || { echo "check_symbols: no entries found" >&2; exit 1; }

while IFS=$'\t' read -r kind tex partner; do
  convert "$tex"
  if [[ "$kind" == ok ]]; then
    if grep -q "Could not convert" <<<"$warn"; then
      report FAIL "$tex" "$(grep -m1 'Could not convert' <<<"$warn")"
    elif ! grep -q "<math" <<<"$mathml"; then
      report FAIL "$tex" "no <math> in pandoc output"
    else
      report PASS "$tex" "converts"
    fi
  else
    if grep -q "Could not convert" <<<"$warn"; then
      report PASS "$tex" "avoid: fails to convert"
      continue
    fi
    if [[ -z "$partner" ]]; then
      report FAIL "$tex" "avoid: converts, and has no partner to compare with"
      continue
    fi
    bad="$mathml"; convert "$partner"; good="$mathml"
    if [[ "$bad" != "$good" ]]; then
      report PASS "$tex" "avoid: renders differently from $partner"
    else
      report FAIL "$tex" "avoid: renders the same as $partner"
    fi
  fi
done <<<"$entries"

echo
echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
