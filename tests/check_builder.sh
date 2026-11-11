#!/usr/bin/env bash
# Exercise the public build interface, including warnings and strict failures.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
builder="$here/../skills/pdf2epub/build_epub.sh"
work="$(mktemp -d "${TMPDIR:-/tmp}/check_builder.XXXXXX")"
trap 'rm -rf "$work"' EXIT
mkdir "$work/source with spaces" "$work/output with spaces"
source_dir="$work/source with spaces"
out="$work/output with spaces/book.epub"

cat > "$source_dir/figure with spaces.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="80" height="40">
  <rect width="80" height="40" fill="navy"/>
</svg>
SVG
cat > "$source_dir/paper.md" <<'MD'
---
title: Builder fixture
---

# A formula and a figure

$$x^2 + 1 \tag{1}$$

![A blue rectangle.](<figure with spaces.svg>)
MD
cat > "$source_dir/bad-math.md" <<'MD'
---
title: Unsupported mathematics
---

$\unknownpdfepubmacro{x}$
MD
cat > "$source_dir/missing-image.md" <<'MD'
---
title: Missing figure
---

![Missing figure.](missing.png)
MD

fail() { echo "FAIL  $*" >&2; exit 1; }

# Run from a different directory so image lookup cannot rely on the caller's CWD.
(cd "$work" && "$builder" --strict "$source_dir/paper.md" "$out") \
  > "$work/stdout" 2> "$work/stderr"
[[ ! -s "$work/stderr" ]] || fail "unexpected strict-build diagnostics"
[[ "$(cat "$work/stdout")" == "$out" ]] || fail "output path was not reported"
unzip -t "$out" > /dev/null
unzip -Z1 "$out" > "$work/entries"
grep -q '\.svg$' "$work/entries" || fail "figure was not embedded"
svg_entry="$(sed -n '/\.svg$/p' "$work/entries")"
unzip -p "$out" "$svg_entry" > "$work/embedded.svg"
cmp -s "$source_dir/figure with spaces.svg" "$work/embedded.svg" \
  || fail "SVG artwork was changed or rasterised"
echo "PASS  strict build preserves SVG artwork with spaces in source and output paths"

cp "$out" "$work/original.epub"
for fixture in bad-math missing-image; do
  if "$builder" --strict "$source_dir/$fixture.md" "$out" \
    > "$work/stdout" 2> "$work/stderr"; then
    fail "strict mode accepted $fixture"
  fi
  [[ ! -s "$work/stdout" ]] || fail "strict failure reported a successful output"
  grep -q 'strict build failed' "$work/stderr" || fail "missing strict diagnostic"
  cmp -s "$out" "$work/original.epub" || fail "strict failure replaced the existing EPUB"
  if "$builder" --strict "$source_dir/$fixture.md" "$work/rejected.epub" \
    > "$work/stdout" 2> "$work/stderr"; then
    fail "strict mode accepted $fixture on a fresh output"
  fi
  [[ ! -e "$work/rejected.epub" ]] || fail "strict failure published an EPUB"

  "$builder" "$source_dir/$fixture.md" "$work/legacy.epub" \
    > "$work/stdout" 2> "$work/stderr"
  grep -q '\[WARNING\]' "$work/stderr" || fail "legacy mode hid the $fixture warning"
  [[ "$(cat "$work/stdout")" == "$work/legacy.epub" ]] || fail "legacy output path missing"
  unzip -t "$work/legacy.epub" > /dev/null
  echo "PASS  $fixture fails strictly, preserves output, and warns in legacy mode"
done

mkdir "$work/empty-path"
if PATH="$work/empty-path" "$builder" "$source_dir/paper.md" "$out" \
  > "$work/stdout" 2> "$work/stderr"; then
  fail "missing pandoc was accepted"
fi
grep -q 'missing dependency: pandoc' "$work/stderr" || fail "missing dependency was not named"
cmp -s "$out" "$work/original.epub" || fail "dependency failure replaced the EPUB"
echo "PASS  missing dependency is reported before building"
