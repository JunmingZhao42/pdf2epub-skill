---
name: pdf2epub
description: Convert PDF papers to EPUB by faithfully transcribing prose and mathematics, then building with pandoc. Use when the user asks for a PDF or paper as an EPUB, or wants a paper readable on their phone. Accept local PDFs, links, DOIs, arXiv IDs, and optional Zotero items.
metadata:
  version: "2.1"
---

# PDF → EPUB by transcription

Read the PDF visually and write a faithful Markdown transcription with LaTeX maths.
Then `build_epub.sh` turns it into an EPUB with pandoc. This workflow supports both
Claude Code and Codex; use the reading tools available in the current host.

Resolve `skill_dir` to the absolute directory containing this loaded `SKILL.md`,
following symlinks if needed. The builder and `symbols.md` are beside this file;
they do not depend on the current working directory or the host's installation path.

## Rules

- **Transcribe, never summarise.** Every sentence, footnote, theorem, proof and
  reference goes in, in the original order and wording. Don't fix the authors' typos.
- Transcription inputs are processed by the selected agent's model provider.
  Poppler and pandoc run locally. Do not upload the paper to a third-party
  conversion service or use an iCloud hand-off.
- Never write into `~/Zotero/` (database or `storage/`). Read the database read-only.
- Use normal permission escalation if access to a source or destination is blocked.
  Keep conversion files in the working directory selected below.

## 1. Choose a working directory and find the PDF

Use the user's working directory if specified; otherwise create
`pdf2epub/<short-slug>/` inside the current workspace. Create the directory if needed
and set `workdir` to its absolute path. Keep downloaded PDFs, Markdown, rendered
pages, figures, and the EPUB there; read supplied local PDFs in place. Choose a
fresh slug if the directory already contains another conversion.

**A local PDF.** Read it from its supplied path; leave the source unchanged.

**A link, DOI or arXiv ID.** Download into a new empty folder and check the file type:

```bash
mkdir -p "$workdir"
curl -fL --max-time 120 -o "$workdir/paper.pdf" "<pdf url>"   # arXiv: https://arxiv.org/pdf/<id>
file "$workdir/paper.pdf"                                    # must say "PDF document"
```

For a DOI, find an open-access PDF from the landing page. If there isn't one, say so.

**A title of a paper in Zotero** (optional: only if the user has Zotero
with its data folder at `~/Zotero`; needs `sqlite3`). If there is no
`~/Zotero/zotero.sqlite`, ask for a link or the PDF instead.

```bash
sqlite3 -readonly "file:$HOME/Zotero/zotero.sqlite?immutable=1" "
SELECT p.itemID, v.value, ai.key, a.path
FROM items p
JOIN itemData d ON d.itemID = p.itemID
JOIN fields f ON f.fieldID = d.fieldID AND f.fieldName = 'title'
JOIN itemDataValues v ON v.valueID = d.valueID
JOIN itemAttachments a ON a.parentItemID = p.itemID AND a.contentType = 'application/pdf'
JOIN items ai ON ai.itemID = a.itemID
WHERE v.value LIKE '%<words from the title>%';"
```

The file is `~/Zotero/storage/<attachment key>/<path without "storage:">`. If several
items match, ask which one. If the file is missing, it hasn't synced to this Mac: ask
before starting Zotero (`open -a Zotero`) and wait for the file to appear.

**Otherwise** (for example "the PDF I just AirDropped"), run `ls -t ~/Downloads/*.pdf | head -3`.
Confirm with the user if the right file is unclear.

## 2. Plan

Check `pdfinfo`, `pdftoppm`, and `pdftocairo` are available, along with pandoc 3+,
zsh, and perl.
Explain any missing dependency before attempting transcription.

```bash
pdfinfo "<pdf>" | grep -E "Pages|Title"
```

- Write `<short-slug>.md` in `workdir` and append each chunk as it is completed.
- **Claude Code:** use native PDF reading when available, in chunks of at most
  10 pages (`Read` with `pages: "1-10"`, then `"11-20"`). Use smaller chunks for
  dense mathematics; fall back to rendered page images if native reading is absent.
- **Codex:** render pages with Poppler and inspect the resulting PNGs through the
  host's image-viewing tool, using absolute paths. Start with one or two pages for
  dense mathematics. Rendering a page does not count as reading it: view each image
  before transcribing that page. For example:

  ```bash
  pdftoppm -png -r 150 -f 1 -l 2 "<pdf>" "$workdir/page"
  ```

  Inspect the filenames produced rather than assuming their zero-padding.
- Extracted text may assist with prose, but page images are the reference for
  notation and layout. If no image-viewing tool is available, explain the limitation
  rather than presenting text extraction as a visually checked transcription.
- Over about 40 pages, explain that transcription will take longer and describe
  the chunking approach before starting. Give a time estimate only if justified.

## 3. Transcribe

First read `symbols.md` in `skill_dir`. It lists how to write each known symbol
so that it converts, and the pitfalls to avoid. Follow it.

Start the file with front matter, then append each chunk as soon as it's done, so a
long paper is never lost midway:

```markdown
---
title: "<paper title>"
author: ["<Author One>", "<Author Two>"]
date: "<year>"
---
```

Formatting rules:

- **Headings.** Use `#` for numbered sections and `##` for subsections. Keep the
  numbers ("# 3 Exchange Laws"). Put the abstract under `# Abstract`.
- **Inline maths.** `$…$`, including single symbols in prose: write "$p \ast q$", not
  "p ∗ q". Write symbols as `symbols.md` says.
- **Display maths.** Put `$$ … $$` on its own lines. Keep the equation numbers with
  `\tag{n}`; the build script turns them into "(n)". Multi-line displays use
  `\begin{aligned} … \end{aligned}` or `\begin{array}`.
- **Avoid** text-mode macros inside maths (`\textasteriskcentered`, `{\it …}`, `\bf`)
  and package-specific macros. If the paper defines its own macros, expand them.
- **Theorems, lemmas, definitions.** Start the paragraph with
  `**Lemma 3.7.**`. Proofs start with `*Proof.*` and end with ∎.
- **Footnotes** use `[^n]` with `[^n]: …` at the end of that section.
- **Tables** use pipe tables. Fall back to HTML for merged cells.
- **Figures and diagrams.** Preserve vector artwork as SVG in the EPUB. Read
  [figures.md](figures.md) when a paper contains figures: it explains vector
  extraction, crop coordinates, and checks for embedded raster content. Keep
  captions as ordinary Markdown text using figure syntax, for example
  `![Figure 2: Caption.](figure-2.svg)`. PNG page renders are for visual inspection;
  they do not replace the final vector figure. Report raster-only sources or
  extraction failures rather than silently substituting bitmap figures.
- **Skip** running headers and footers, page numbers, line numbers and publisher
  boilerplate, and rejoin words hyphenated across lines.
- **References** go in a final `# References` section, one entry per paragraph,
  keeping the labels ("[8]").

When a symbol is unclear, zoom in: render the page with
`pdftoppm -png -r 200 -f <p> -l <p> "<pdf>" "$workdir/zoom"` and view the image.
Report any ambiguity that remains; do not guess.

## 4. Build and check

```bash
"$skill_dir/build_epub.sh" --strict "$workdir/<slug>.md" "$workdir/<slug>.epub"
```

- A strict build fails for unconverted TeX or missing resources. Fix the formulas
  or paths and rebuild. If the problem cannot be resolved, report it and retain the
  Markdown; do not deliver an earlier EPUB as if it were the current result.
- Verify coverage of every source page, including footnotes, figures, and references.
- Check that vector figures are still SVG resources in the EPUB and have not been
  replaced by raster content. Report any source figures that could not be preserved
  as vectors, including photographs or scans supplied as bitmaps.
- Spot-check the key results: compare two or three main formulas against the PDF
  page images. A successful build establishes conversion, not transcription accuracy.

## Adding a symbol

When a paper uses a symbol that `symbols.md` doesn't cover, or one that needed a
second try (it didn't convert, or the PDF text layer misled you), prepare a row for
the right section of `symbols.md`. Add it there if the installed glossary is
writable; otherwise save it in `$workdir/symbols-proposed.md`:

1. Check the LaTeX converts, and to the right glyph. The first command prints
   "converts" or pandoc's complaint. The second shows the glyphs it produced:
   ```bash
   printf '%s\n' '$<latex>$' | pandoc -f markdown -t html --math-method=mathml 2>&1 >/dev/null \
     | grep "Could not convert" || echo converts
   printf '%s\n' '$<latex>$' | pandoc -f markdown -t html --math-method=mathml \
     | grep -oE "<m[ion][^>]*>[^<]*</m[ion]>"
   ```
2. Add the row: the glyph, the LaTeX that converts, and one short note on the pitfall
   (what the text layer showed, or what failed). If something must be avoided, put it
   under "Avoid".
3. In your final report, identify the added rows or link to the proposed rows.

Keep the notes general. A paper-specific macro goes in only if its expansion is a
pattern other papers will reuse.

## 5. Deliver

Use the host's file-attachment capability when available (for example,
`SendUserFile` with `display: "attach"`). Otherwise provide a clickable Markdown
link to the EPUB's absolute filesystem path, wrapping paths containing spaces in
angle brackets. Retain the Markdown beside it and link to that source too. If the
user requests local-only delivery, leave both files in the working directory and
provide their local links.

On an iPhone or iPad, open the EPUB via Share → Books; on a Mac, open it in Books.
Report unresolved reading ambiguities and distinguish build checks from visual
source comparisons. Do not claim reading-app validation unless it was performed.
