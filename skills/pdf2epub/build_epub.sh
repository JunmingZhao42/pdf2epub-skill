#!/bin/zsh
# Build an EPUB from a transcribed Markdown file with pandoc.
# Usage: build_epub.sh [--strict] <paper.md> <out.epub>
# Title and author come from the Markdown's YAML front matter.
# Maths: $...$ / $$...$$ rendered as MathML. Hyphenation is off.
set -euo pipefail

strict=0
if [[ "${1:-}" == --strict ]]; then
  strict=1
  shift
fi
if [[ $# -ne 2 || "${1:-}" == --* ]]; then
  echo "usage: build_epub.sh [--strict] <paper.md> <out.epub>" >&2
  exit 2
fi
md="$1"
out="$2"
[[ -f "$md" ]] || { echo "build_epub: no such file: $md" >&2; exit 1; }
[[ ! -d "$out" ]] || { echo "build_epub: output is a directory: $out" >&2; exit 1; }

for tool in pandoc perl mktemp dirname cat grep sed rm mv; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "build_epub: missing dependency: $tool (see README requirements)" >&2
    exit 1
  }
done
pandoc_major="$(pandoc --version | sed -n '1s/^pandoc \([0-9][0-9]*\).*/\1/p')"
if [[ -z "$pandoc_major" || "$pandoc_major" -lt 3 ]]; then
  echo "build_epub: pandoc 3 or later is required" >&2
  exit 1
fi

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
  -o "$work/output.epub" 2> "$work/warnings.txt" || { cat "$work/warnings.txt" >&2; exit 1; }

# Report formulas pandoc could not convert (they appear as raw TeX in the book).
if grep -q "Could not convert TeX math" "$work/warnings.txt"; then
  echo "build_epub: formulas left as raw TeX (fix these in the Markdown and rebuild):" >&2
fi
cat "$work/warnings.txt" >&2

if (( strict )) && grep -Eq 'Could not convert TeX math|Could not fetch resource' "$work/warnings.txt"; then
  echo "build_epub: strict build failed; fix the formulas or resource paths above and rebuild. Output was not replaced." >&2
  exit 1
fi

# Publish only after validation, preserving an existing book on strict failure.
mv -f -- "$work/output.epub" "$out"
echo "$out"
