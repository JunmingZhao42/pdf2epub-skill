#!/bin/zsh
# Build an EPUB from a transcribed Markdown file with pandoc.
# Usage: build_epub.sh <paper.md> <out.epub>
# Title and author come from the Markdown's YAML front matter.
# Maths: $...$ / $$...$$ rendered as MathML. Hyphenation is off.
set -euo pipefail

md="${1:?usage: build_epub.sh <paper.md> <out.epub>}"
out="${2:?usage: build_epub.sh <paper.md> <out.epub>}"
[[ -f "$md" ]] || { echo "build_epub: no such file: $md" >&2; exit 1; }

work="$(mktemp -d "${TMPDIR:-/tmp}/pdf2epub.XXXXXX")"
trap 'rm -rf "$work"' EXIT

# pandoc's MathML writer drops \tag{n}; keep equation numbers as "(n)".
perl -pe 's/\\tag\*?\{([^{}]*)\}/\\qquad($1)/g' "$md" > "$work/input.md"

# Default pandoc EPUB stylesheet plus rules that stop Apple Books hyphenating.
{
  pandoc --print-default-data-file epub.css
  cat <<'CSS'

body, p, li, dd, dt, blockquote, td, th, figcaption {
  -webkit-hyphens: none;
  -epub-hyphens: none;
  hyphens: none;
}
img { max-width: 100%; }
CSS
} > "$work/style.css"

pandoc "$work/input.md" \
  -f markdown+tex_math_dollars+raw_html-raw_tex \
  -t epub3 --math-method=mathml \
  --toc --toc-depth=2 --split-level=2 \
  --resource-path="$(dirname "$md")" \
  --css="$work/style.css" \
  --metadata lang=en \
  -o "$out" 2> "$work/warnings.txt" || { cat "$work/warnings.txt" >&2; exit 1; }

# Report formulas pandoc could not convert (they appear as raw TeX in the book).
if grep -q "Could not convert TeX math" "$work/warnings.txt"; then
  echo "build_epub: formulas left as raw TeX (fix these in the Markdown and rebuild):" >&2
  grep -o "Could not convert TeX math .*, rendering as TeX" "$work/warnings.txt" \
    | sed -e 's/^Could not convert TeX math /  /' -e 's/, rendering as TeX$//' >&2
fi
grep "^\[WARNING\]" "$work/warnings.txt" | grep -v "Could not convert TeX math" >&2 || true

echo "$out"
